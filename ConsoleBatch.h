/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
    Copyright (C) 2007-2009  Joseph Artsimovich <joseph_a@mail.ru>

    ConsoleBatch - Batch processing scanned pages from command line.
    Copyright (C) 2011 Petr Kovar <pejuko@gmail.com>

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

#ifndef CONSOLEBATCH_H_
#define CONSOLEBATCH_H_

#include "MainWindow.h"
#include "NonCopyable.h"
#include "IntrusivePtr.h"
#include "BackgroundTask.h"
#include "FilterResult.h"
#include "OutputFileNameGenerator.h"
#include "PageId.h"
#include "PageView.h"
#include <QString>
#include <vector>
#include "ImageFileInfo.h"
#include "ThumbnailPixmapCache.h"
#include "OutputFileNameGenerator.h"


class ConsoleBatch
{
public:
	ConsoleBatch(MainWindow* main_w);

	//virtual ~ConsoleBatch();

	void process(
			//std::vector<ImageInfo> const& images,
			std::vector<ImageFileInfo> const& images,
			QString                    const& output_dir,
			Qt::LayoutDirection        const  layout);

private:
	bool batch;
	bool debug;
	MainWindow *main_wnd;
	IntrusivePtr<FileNameDisambiguator> disambiguator;

	BackgroundTaskPtr createCompositeTask(
		StageSequence const* m_ptrStages,
		IntrusivePtr<ThumbnailPixmapCache> const m_ptrThumbnailCache,
		OutputFileNameGenerator const& m_outFileNameGen,
		PageInfo const& page,
		IntrusivePtr<ProjectPages> const m_ptrPages,
		int const last_filter_idx);
};

#endif
