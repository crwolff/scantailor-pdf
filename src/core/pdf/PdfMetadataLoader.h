/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
    Copyright (C) 2007-2017  Joseph Artsimovich <joseph_a@mail.ru>		
		Copyright (C) 2017 Daniel Just
		
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

#ifndef PDFMETADATALOADER_H_
#define PDFMETADATALOADER_H_

#include "../ImageMetadataLoader.h"
#include "VirtualFunction.h"
#include <vector>

class QFile;
class ImageMetadata;

class PdfMetadataLoader : public ImageMetadataLoader
{
public:
	/**
	 * \brief Register this loader in the global registry.
	 *
	 * The same restrictions apply here as for
	 * ImageMetadataLoader::registerLoader()
	 */
	static void registerMyself();
protected:
	virtual Status loadMetadata(
		QFile& file,
		VirtualFunction1<void, ImageMetadata const&>& out);
};

#endif
