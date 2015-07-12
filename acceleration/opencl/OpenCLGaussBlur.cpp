/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
    Copyright (C) 2015  Joseph Artsimovich <joseph.artsimovich@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "OpenCLGaussBlur.h"
#include "Transpose.h"
#include "Utils.h"
#include "PerformanceTimer.h"
#include "imageproc/GaussBlur.h"

using namespace imageproc::gauss_blur_impl;

namespace opencl
{

namespace
{

/**
 * @see imageproc::gauss_blur_impl::calcBackwardPassInitialConditions()
 */
void initHistoryUpdateMatrix(FilterParams const& p, cl_float3& m1, cl_float3& m2, cl_float3& m3)
{
	float const normalizer = 1.f /
		((1.f + p.a1 - p.a2 + p.a3) * (1.f + p.a2 + (p.a1 - p.a3) * p.a3));

	m1.s[0] = normalizer * (-p.a3 * p.a1 + 1.f - p.a3 * p.a3 - p.a2);
	m2.s[0] = normalizer * (p.a3 + p.a1) * (p.a2 + p.a3 * p.a1);
	m3.s[0] = normalizer * p.a3 * (p.a1 + p.a3 * p.a2);
	m1.s[1] = normalizer * (p.a1 + p.a3 * p.a2);
	m2.s[1] = normalizer * -(p.a2 - 1.f) * (p.a2 + p.a3 * p.a1);
	m3.s[1] = normalizer * -(p.a3 * p.a1 + p.a3 * p.a3 + p.a2 - 1.f) * p.a3;
	m1.s[2] = normalizer * (p.a3 * p.a1 + p.a2 + p.a1 * p.a1 - p.a2 * p.a2);
	m2.s[2] = normalizer * (p.a1 * p.a2 + p.a3 * p.a2 * p.a2 - p.a1 * p.a3 * p.a3
			- p.a3 * p.a3 * p.a3 - p.a3 * p.a2 + p.a3);
	m3.s[2] = normalizer * p.a3 * (p.a1 + p.a3 * p.a2);
}

void horizontalPass(
	cl::CommandQueue const& command_queue, cl::Program const& program,
	OpenCLGrid<float> const& src_grid, OpenCLGrid<float> const& dst_grid,
	float const sigma, std::vector<cl::Event>& deps, cl::Event& evt)
{
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();
	size_t const cacheline_size = device.getInfo<CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE>();
	size_t const max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();
	size_t const wg_size = std::min<size_t>(max_wg_size, cacheline_size / sizeof(float));

	FilterParams const p(sigma);

	cl_float3 m1, m2, m3;
	initHistoryUpdateMatrix(p, m1, m2, m3);

	cl::Kernel kernel(program, "gauss_blur_1d");
	int idx = 0;
	kernel.setArg(idx++, src_grid.width());
	kernel.setArg(idx++, src_grid.height());
	kernel.setArg(idx++, src_grid.buffer());
	kernel.setArg(idx++, src_grid.offset());
	kernel.setArg(idx++, src_grid.stride());
	kernel.setArg(idx++, cl_int(1));
	kernel.setArg(idx++, dst_grid.buffer());
	kernel.setArg(idx++, dst_grid.offset());
	kernel.setArg(idx++, dst_grid.stride());
	kernel.setArg(idx++, cl_int(1));
	kernel.setArg(idx++, cl_float4{p.B, p.a1, p.a2, p.a3});
	kernel.setArg(idx++, m1);
	kernel.setArg(idx++, m2);
	kernel.setArg(idx++, m3);

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(src_grid.height(), wg_size)),
		cl::NDRange(wg_size),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);
}

void verticalPass(
	cl::CommandQueue const& command_queue, cl::Program const& program,
	OpenCLGrid<float> const& src_grid, OpenCLGrid<float> const& dst_grid,
	float const sigma, std::vector<cl::Event>& deps, cl::Event& evt)
{
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();
	size_t const cacheline_size = device.getInfo<CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE>();
	size_t const max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();
	size_t const wg_size = std::min<size_t>(max_wg_size, cacheline_size / sizeof(float));

	FilterParams const p(sigma);

	cl_float3 m1, m2, m3;
	initHistoryUpdateMatrix(p, m1, m2, m3);

	cl::Kernel kernel(program, "gauss_blur_1d");
	int idx = 0;
	kernel.setArg(idx++, src_grid.height());
	kernel.setArg(idx++, src_grid.width());
	kernel.setArg(idx++, src_grid.buffer());
	kernel.setArg(idx++, src_grid.offset());
	kernel.setArg(idx++, cl_int(1));
	kernel.setArg(idx++, src_grid.stride());
	kernel.setArg(idx++, dst_grid.buffer());
	kernel.setArg(idx++, dst_grid.offset());
	kernel.setArg(idx++, cl_int(1));
	kernel.setArg(idx++, dst_grid.stride());
	kernel.setArg(idx++, cl_float4{p.B, p.a1, p.a2, p.a3});
	kernel.setArg(idx++, m1);
	kernel.setArg(idx++, m2);
	kernel.setArg(idx++, m3);

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(src_grid.width(), wg_size)),
		cl::NDRange(wg_size),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);
}

void copy1PxPadding(
	cl::CommandQueue const& command_queue, cl::Program const& program,
	OpenCLGrid<float>& grid, std::vector<cl::Event>& deps, cl::Event& evt)
{
	assert(grid.padding() > 0);

	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();
	size_t const max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();

	// Copy the top outer layer.
	command_queue.enqueueCopyBuffer(
		grid.buffer(), grid.buffer(),
		grid.offset() * sizeof(float),
		(grid.offset() - grid.stride()) * sizeof(float),
		grid.width() * sizeof(float),
		&deps, &evt
	);
	deps.clear();
	deps.push_back(evt);

	// Copy the bottom outer layer.
	command_queue.enqueueCopyBuffer(
		grid.buffer(), grid.buffer(),
		(grid.offset() + (grid.height() - 1) * grid.stride()) * sizeof(float),
		(grid.offset() + grid.height() * grid.stride()) * sizeof(float),
		grid.width() * sizeof(float),
		&deps, &evt
	);
	deps.clear();
	deps.push_back(evt);

	// Copy the left outer layer.
	{
		cl::Kernel kernel(program, "copy_1px_column");
		int idx = 0;
		kernel.setArg(idx++, grid.height());
		kernel.setArg(idx++, grid.buffer());
		kernel.setArg(idx++, grid.offset());
		kernel.setArg(idx++, grid.stride());
		kernel.setArg(idx++, -1);

		command_queue.enqueueNDRangeKernel(
			kernel,
			cl::NullRange,
			cl::NDRange(thisOrNextMultipleOf(grid.height(), max_wg_size)),
			cl::NDRange(max_wg_size),
			&deps,
			&evt
		);
		deps.clear();
		deps.push_back(evt);
	}

	// Copy the right outer layer.
	{
		cl::Kernel kernel(program, "copy_1px_column");
		int idx = 0;
		kernel.setArg(idx++, grid.height());
		kernel.setArg(idx++, grid.buffer());
		kernel.setArg(idx++, grid.offset() + grid.width() - 1);
		kernel.setArg(idx++, grid.stride());
		kernel.setArg(idx++, 1);

		command_queue.enqueueNDRangeKernel(
			kernel,
			cl::NullRange,
			cl::NDRange(thisOrNextMultipleOf(grid.height(), max_wg_size)),
			cl::NDRange(max_wg_size),
			&deps,
			&evt
		);
		deps.clear();
		deps.push_back(evt);
	}

	{
		cl::Kernel kernel(program, "copy_padding_corners");
		int idx = 0;
		kernel.setArg(idx++, grid.width());
		kernel.setArg(idx++, grid.height());
		kernel.setArg(idx++, grid.buffer());
		kernel.setArg(idx++, grid.offset());
		kernel.setArg(idx++, grid.stride());

		command_queue.enqueueTask(
			kernel,
			&deps,
			&evt
		);
		deps.clear();
		deps.push_back(evt);
	}
}

void verticallyTraversedSkewedPassInPlace(
	cl::CommandQueue const& command_queue, cl::Program const& program,
	OpenCLGrid<float>& grid, float const sigma, float const dx,
	std::vector<cl::Event>& deps, cl::Event& evt)
{
	int const width = grid.width();
	int const height = grid.height();
	cl::Context const context = command_queue.getInfo<CL_QUEUE_CONTEXT>();
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();
	size_t const cacheline_size = device.getInfo<CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE>();
	size_t const max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();

	FilterParams const p(sigma);
	cl_float3 m1, m2, m3;
	initHistoryUpdateMatrix(p, m1, m2, m3);

	copy1PxPadding(command_queue, program, grid, deps, evt);

	// In the CPU version of this code we build a reference skewed line,
	// which is an array of InterpolatedCoord structures indexed by y.
	// In OpenCL version we don't construct that array explicitly, but
	// instead build its elements on demand (see get_interpolated_coord()
	// in gauss_blur.cl). We then "move" that line by adding values in
	// [min_x_offset, max_x_offset] range to InterpolatedCoord::lower_bound.
	// Now let's calculate that range.
	int min_x_offset, max_x_offset; // These don't change once computed.
	{
		int const x0 = 0;
		int const x1 = static_cast<int>(std::floor(float(height - 1) * dx));
		if (x0 < x1) {
			// '\'-like skewed line

			// x1 + min_x_offset == -1
			min_x_offset = -1 - x1;

			// x0 + 1 + max_x_offset == width
			max_x_offset = width - 1 - x0;
		} else {
			// '/'-like skewed line

			// x0 + min_x_offset == -1
			min_x_offset = -1 - x0;

			// x1 + 1 + max_x_offset == width
			max_x_offset = width - 1 - x1;
		}
	}

	cl::Buffer intermediate_buffer(
		context, CL_MEM_READ_WRITE, grid.totalBytesWithDifferentPadding(1)
	);
	OpenCLGrid<float> intermediate_grid(grid.withDifferentPadding(intermediate_buffer, 1));

	cl::Kernel kernel(program, "gauss_blur_skewed_vert_traversal_stage1");
	int idx = 0;
	kernel.setArg(idx++, cl_int(width));
	kernel.setArg(idx++, cl_int(height));
	kernel.setArg(idx++, grid.buffer());
	kernel.setArg(idx++, grid.offset());
	kernel.setArg(idx++, grid.stride());
	kernel.setArg(idx++, intermediate_grid.buffer());
	kernel.setArg(idx++, intermediate_grid.offset());
	kernel.setArg(idx++, intermediate_grid.stride());
	kernel.setArg(idx++, cl_int(min_x_offset));
	kernel.setArg(idx++, cl_int(max_x_offset));
	kernel.setArg(idx++, cl_float(dx));
	kernel.setArg(idx++, cl_float4{p.B, p.a1, p.a2, p.a3});
	kernel.setArg(idx++, m1);
	kernel.setArg(idx++, m2);
	kernel.setArg(idx++, m3);

	size_t const wg_size_1d = std::min<size_t>(max_wg_size, 16);

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(max_x_offset - min_x_offset + 1, wg_size_1d)),
		cl::NDRange(wg_size_1d),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);

	kernel = cl::Kernel(program, "gauss_blur_skewed_vert_traversal_stage2");
	idx = 0;
	kernel.setArg(idx++, cl_int(width));
	kernel.setArg(idx++, cl_int(height));
	kernel.setArg(idx++, intermediate_grid.buffer());
	kernel.setArg(idx++, intermediate_grid.offset());
	kernel.setArg(idx++, intermediate_grid.stride());
	kernel.setArg(idx++, grid.buffer());
	kernel.setArg(idx++, grid.offset());
	kernel.setArg(idx++, grid.stride());
	kernel.setArg(idx++, cl_float(dx));

	size_t const h_wg_size = std::min<size_t>(max_wg_size, cacheline_size / sizeof(float));
	size_t const v_wg_size = max_wg_size / h_wg_size;

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(width, h_wg_size), thisOrNextMultipleOf(height, v_wg_size)),
		cl::NDRange(h_wg_size, v_wg_size),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);
}

void horizontallyTraversedSkewedPassInPlace(
	cl::CommandQueue const& command_queue, cl::Program const& program,
	OpenCLGrid<float>& grid, float const sigma, float const dy,
	std::vector<cl::Event>& deps, cl::Event& evt)
{
	int const width = grid.width();
	int const height = grid.height();
	cl::Context const context = command_queue.getInfo<CL_QUEUE_CONTEXT>();
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();
	size_t const cacheline_size = device.getInfo<CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE>();
	size_t const max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();

	FilterParams const p(sigma);
	cl_float3 m1, m2, m3;
	initHistoryUpdateMatrix(p, m1, m2, m3);

	copy1PxPadding(command_queue, program, grid, deps, evt);

	// In the CPU version of this code we build a reference skewed line,
	// which is an array of InterpolatedCoord structures indexed by x.
	// In OpenCL version we don't construct that array explicitly, but
	// instead build its elements on demand (see get_interpolated_coord()
	// in gauss_blur.cl). We then "move" that line by adding values in
	// [min_y_offset, max_y_offset] range to InterpolatedCoord::lower_bound.
	// Now let's calculate that range.
	int min_y_offset, max_y_offset; // These don't change once computed.
	{
		int const y0 = 0;
		int const y1 = static_cast<int>(std::floor(float(width - 1) * dy));
		if (y0 < y1) {
			// '\'-like skewed line

			// y1 + min_y_offset == -1
			min_y_offset = -1 - y1;

			// y0 + 1 + max_y_offset == height
			max_y_offset = height - 1 - y0;
		} else {
			// '/'-like skewed line

			// y0 + min_y_offset == -1
			min_y_offset = -1 - y0;

			// y1 + 1 + max_y_offset == height
			max_y_offset = height - 1 - y1;
		}
	}

	cl::Buffer intermediate_buffer(
		context, CL_MEM_READ_WRITE, grid.totalBytesWithDifferentPadding(1)
	);
	OpenCLGrid<float> intermediate_grid(grid.withDifferentPadding(intermediate_buffer, 1));

	cl::Kernel kernel(program, "gauss_blur_skewed_hor_traversal_stage1");
	int idx = 0;
	kernel.setArg(idx++, cl_int(width));
	kernel.setArg(idx++, cl_int(height));
	kernel.setArg(idx++, grid.buffer());
	kernel.setArg(idx++, grid.offset());
	kernel.setArg(idx++, grid.stride());
	kernel.setArg(idx++, intermediate_grid.buffer());
	kernel.setArg(idx++, intermediate_grid.offset());
	kernel.setArg(idx++, intermediate_grid.stride());
	kernel.setArg(idx++, cl_int(min_y_offset));
	kernel.setArg(idx++, cl_int(max_y_offset));
	kernel.setArg(idx++, cl_float(dy));
	kernel.setArg(idx++, cl_float4{p.B, p.a1, p.a2, p.a3});
	kernel.setArg(idx++, m1);
	kernel.setArg(idx++, m2);
	kernel.setArg(idx++, m3);

	size_t const wg_size_1d = std::min<size_t>(max_wg_size, 16);

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(max_y_offset - min_y_offset + 1, wg_size_1d)),
		cl::NDRange(wg_size_1d),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);

	kernel = cl::Kernel(program, "gauss_blur_skewed_hor_traversal_stage2");
	idx = 0;
	kernel.setArg(idx++, cl_int(width));
	kernel.setArg(idx++, cl_int(height));
	kernel.setArg(idx++, intermediate_grid.buffer());
	kernel.setArg(idx++, intermediate_grid.offset());
	kernel.setArg(idx++, intermediate_grid.stride());
	kernel.setArg(idx++, grid.buffer());
	kernel.setArg(idx++, grid.offset());
	kernel.setArg(idx++, grid.stride());
	kernel.setArg(idx++, cl_float(dy));

	size_t const h_wg_size = std::min<size_t>(max_wg_size, cacheline_size / sizeof(float));
	size_t const v_wg_size = max_wg_size / h_wg_size;

	command_queue.enqueueNDRangeKernel(
		kernel,
		cl::NullRange,
		cl::NDRange(thisOrNextMultipleOf(width, h_wg_size), thisOrNextMultipleOf(height, v_wg_size)),
		cl::NDRange(h_wg_size, v_wg_size),
		&deps,
		&evt
	);
	deps.clear();
	deps.push_back(evt);
}

} // anonymous namespace

OpenCLGrid<float> gaussBlur(
	cl::CommandQueue const& command_queue,
	cl::Program const& program,
	OpenCLGrid<float> const& src_grid,
	float h_sigma, float v_sigma,
	std::vector<cl::Event>* wait_for,
	cl::Event* event)
{
	cl::Context const context = command_queue.getInfo<CL_QUEUE_CONTEXT>();
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();

	std::vector<cl::Event> deps;
	if (wait_for) {
		deps.insert(deps.end(), wait_for->begin(), wait_for->end());
	}

	cl::Event evt;

	cl::Buffer dst_buffer(
		context, CL_MEM_READ_WRITE, src_grid.totalBytesWithDifferentPadding(0)
	);
	OpenCLGrid<float> dst_grid(src_grid.withDifferentPadding(dst_buffer, 0));

	if (device.getInfo<CL_DEVICE_LOCAL_MEM_TYPE>() == CL_GLOBAL) {
		// horizontalPass() is going to be slow, but without fast local memory
		// there is no way to accelerate it.

		horizontalPass(command_queue, program, src_grid, dst_grid, h_sigma, deps, evt);
		verticalPass(command_queue, program, dst_grid, dst_grid, v_sigma, deps, evt);
	} else {
		// This device has fast local memory, so we avoid a slow horizontalPass()
		// by doing transpose() -> verticalPass() -> transpose()

		OpenCLGrid<float> transposed = opencl::transpose(
			command_queue, program, src_grid, /*dst_padding=*/0, &deps, &evt
		);
		deps.clear();
		deps.push_back(evt);

		verticalPass(command_queue, program, transposed, transposed, h_sigma, deps, evt);

		opencl::transpose(command_queue, program, transposed, dst_grid, &deps, &evt);
		deps.clear();
		deps.push_back(evt);

		verticalPass(command_queue, program, dst_grid, dst_grid, v_sigma, deps, evt);
	}

	if (event) {
		*event = evt;
	}

	return dst_grid;
}

OpenCLGrid<float> anisotropicGaussBlur(
	cl::CommandQueue const& command_queue,
	cl::Program const& program,
	OpenCLGrid<float> const& src_grid,
	float const dir_x, float const dir_y,
	float const dir_sigma, float const ortho_dir_sigma,
	std::vector<cl::Event>* wait_for, cl::Event* event)
{
	cl::Context const context = command_queue.getInfo<CL_QUEUE_CONTEXT>();
	cl::Device const device = command_queue.getInfo<CL_QUEUE_DEVICE>();

	std::vector<cl::Event> deps;
	if (wait_for) {
		deps.insert(deps.end(), wait_for->begin(), wait_for->end());
	}

	cl::Event evt;

	cl::Buffer dst_buffer(
		context, CL_MEM_READ_WRITE, src_grid.totalBytesWithDifferentPadding(1)
	);
	OpenCLGrid<float> dst_grid = src_grid.withDifferentPadding(dst_buffer, 1);

	HorizontalDecompositionParams const hdp(dir_x, dir_y, dir_sigma, ortho_dir_sigma);
	VerticalDecompositionParams const vdp(dir_x, dir_y, dir_sigma, ortho_dir_sigma);
	bool const horizontal_decomposition = hdp.sigma_x > vdp.sigma_y;

	if (!horizontal_decomposition) {
		verticalPass(command_queue, program, src_grid, dst_grid, vdp.sigma_y, deps, evt);
	} else {
		if (device.getInfo<CL_DEVICE_LOCAL_MEM_TYPE>() == CL_GLOBAL) {
			// horizontalPass() is going to be slow, but without fast local memory
			// there is no way to accelerate it.
			cl::Buffer dst_buffer(
				context, CL_MEM_READ_WRITE, src_grid.totalBytesWithDifferentPadding(1)
			);
			dst_grid = src_grid.withDifferentPadding(dst_buffer, 1);
			horizontalPass(command_queue, program, src_grid, dst_grid, hdp.sigma_x, deps, evt);
		} else {
			// This device has fast local memory, so we avoid a slow horizontalPass()
			// by doing transpose() -> verticalPass() -> transpose()

			OpenCLGrid<float> transposed = opencl::transpose(
				command_queue, program, src_grid, /*dst_padding=*/0, &deps, &evt
			);
			deps.clear();
			deps.push_back(evt);

			verticalPass(command_queue, program, transposed, transposed, hdp.sigma_x, deps, evt);

			opencl::transpose(command_queue, program, transposed, dst_grid, &deps, &evt);
			deps.clear();
			deps.push_back(evt);
		}
	}

#if 0
	// Here we try to choose whether to traverse a skewed line one x unit or one y unit
	// at a time based on whether the line is horizontally or vertically leaning.
	// Unfortunately, it produces larger errors in impulse response compared to a
	// more simple approach below.
	if ((horizontal_decomposition && std::abs(hdp.cot_phi) <= 1.0f) ||
		(!horizontal_decomposition && std::abs(vdp.tan_phi) > 1.0f)){
#else
	if (horizontal_decomposition) {
#endif
		float dx; // The step in x direction.
		float sigma_phi;
		if (horizontal_decomposition) {
			dx = hdp.cot_phi;
			sigma_phi = hdp.sigma_phi;
		} else {
			dx = 1.f / vdp.tan_phi;
			sigma_phi = vdp.sigma_phi;
		}
		float const adjusted_sigma_phi = sigma_phi / std::sqrt(1.0f + dx*dx);

		verticallyTraversedSkewedPassInPlace(
			command_queue, program, dst_grid, adjusted_sigma_phi, dx, deps, evt
		);
	} else {
		float dy; // The step in y direction.
		float sigma_phi;
		if (horizontal_decomposition) {
			dy = 1.f / hdp.cot_phi;
			sigma_phi = hdp.sigma_phi;
		} else {
			dy = vdp.tan_phi;
			sigma_phi = vdp.sigma_phi;
		}
		float const adjusted_sigma_phi = sigma_phi / std::sqrt(1.0f + dy*dy);

		if (device.getInfo<CL_DEVICE_LOCAL_MEM_TYPE>() == CL_GLOBAL) {
			// horizontallyTraversedSkewedPassInPlace() is going to be slow, but without
			// fast local memory there is no way to accelerate it.

			horizontallyTraversedSkewedPassInPlace(
				command_queue, program, dst_grid, adjusted_sigma_phi, dy, deps, evt
			);
		} else {
			// This device has fast local memory, so we avoid a slow horizontallyTraversedSkewedPass()
			// by doing transpose() -> verticallyTraversedSkewedPass() -> transpose()

			OpenCLGrid<float> transposed = opencl::transpose(
				command_queue, program, dst_grid, /*dst_padding=*/1, &deps, &evt
			);
			deps.clear();
			deps.push_back(evt);

			verticallyTraversedSkewedPassInPlace(
				command_queue, program, transposed, adjusted_sigma_phi, dy, deps, evt
			);

			opencl::transpose(command_queue, program, transposed, dst_grid, &deps, &evt);
			deps.clear();
			deps.push_back(evt);
		}
	}

	if (event) {
		*event = evt;
	}

	return dst_grid;
}

} // namespace opencl
