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

#include "PageLayout.h"
#include "MatchSizeMode.h"
#include "Alignment.h"
#include "RelativeMargins.h"
#include "AbstractImageTransform.h"
#include "Utils.h"
#include <QTransform>
#include <QtGlobal>
#include <QMarginsF>
#include <algorithm>

namespace page_layout
{

PageLayout::PageLayout(
	QRectF const& unscaled_content_rect, QSizeF const& aggregate_hard_size,
	MatchSizeMode const& match_size_mode, Alignment const& alignment,
	RelativeMargins const& margins)
{
	m_innerRect = unscaled_content_rect;
	m_scaleFactor = 1.0;

	if (match_size_mode == MatchSizeMode::SCALE) {
		// aggregate_size = content_size * scale + margins * width * scale
		// Solving for scale:
		// scale = aggregate_size / (content_size + margins * width)
		qreal const x_scale = aggregate_hard_size.width() /
			(m_innerRect.width() + (margins.left() + margins.right()) * m_innerRect.width());
		qreal const y_scale = aggregate_hard_size.height() /
			(m_innerRect.height() + (margins.top() + margins.bottom()) * m_innerRect.width());

		if (x_scale > 1.0 && y_scale > 1.0) {
			m_scaleFactor = std::min(x_scale, y_scale);
		} else if (x_scale < 1.0 && y_scale < 1.0) {
			m_scaleFactor = std::max(x_scale, y_scale);
		}

		m_innerRect.setWidth(m_innerRect.width() * m_scaleFactor);
		m_innerRect.setHeight(m_innerRect.height() * m_scaleFactor);
	}

	m_middleRect = margins.extendContentRect(m_innerRect);

	QMarginsF const soft_margins(
		Utils::calcSoftMarginsPx(
			m_middleRect.size(), aggregate_hard_size, match_size_mode, alignment
		)
	);

	m_outerRect = m_middleRect.adjusted(
		-soft_margins.left(), -soft_margins.top(),
		soft_margins.right(), soft_margins.bottom()
	);
}

void
PageLayout::absorbScalingIntoTransform(AbstractImageTransform& transform)
{
	if (m_scaleFactor != 1.0) {
		transform.scale(m_scaleFactor, m_scaleFactor);
		m_innerRect.moveTopLeft(m_innerRect.topLeft() * m_scaleFactor);
		m_middleRect.moveTopLeft(m_middleRect.topLeft() * m_scaleFactor);
		m_outerRect.moveTopLeft(m_outerRect.topLeft() * m_scaleFactor);
		m_scaleFactor = 1.0;
	}
}

} // namespace page_layout
