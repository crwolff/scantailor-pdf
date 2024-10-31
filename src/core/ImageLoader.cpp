/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
    Copyright (C)  Joseph Artsimovich <joseph.artsimovigh@gmail.com>

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

#include "ImageLoader.h"
#include "TiffReader.h"
#include "JP2Reader.h"
#include "pdf/PdfReader.h"
#include "ImageId.h"
#include <QImage>
#include <QImageReader>
#include <QString>
#include <QIODevice>
#include <QFile>
#include <QDebug>

QImage
ImageLoader::load(ImageId const& image_id)
{
	return load(image_id.filePath(), image_id.zeroBasedPage());
}

QImage
ImageLoader::load(QString const& file_path, int const page_num)
{
	QFile file(file_path);
	if (!file.open(QIODevice::ReadOnly)) {
		return QImage();
	}
	return load(file, page_num);
}

QImage
ImageLoader::load(QFile& file, int const page_num)
{
	if (TiffReader::canRead(file)) {
		return TiffReader::readImage(file, page_num);
	}

	if (JP2Reader::peekMagic(file)) {
		return JP2Reader::readImage(file);
	}

	if (PdfReader::seemsLikePdf(file)) {
		return PdfReader::readImage(file, page_num);
	}

	QImage image;
	QImageReader(&file).read(&image);
	return image;
}
