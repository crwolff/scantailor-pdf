/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
		Copyright (C) 2017-2024 Daniel Just
		
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

#include "PdfReader.h"
#include "../ImageMetadata.h"
#include "../ImageLoader.h"
#include <QIODevice>
#include <QImage>
#include <QImageReader>
#include <QFile>
#include <QByteArray>

ImageMetadataLoader::Status
PdfReader::readMetadata(QFile& file,
	VirtualFunction1<void, ImageMetadata const&>& out)
{
	PdfMemDocument pdfDoc;
	pdfDoc.Load(file.fileName().toStdString());

	QSize dimensions(0, 0);
	qint64 width = 0;
	qint64 height = 0;
	
	auto& pPage = pdfDoc.GetPages().GetPageAt(0);

	auto* pResources = pPage.GetResources();
	if (!pResources) {
		return ImageMetadataLoader::NO_IMAGES;
	}

	PdfDictionary& resourceDict = pResources->GetDictionary();
	auto xObjectIterator = pResources->GetResourceIterator(PdfResourceType::XObject);

	for (auto it = xObjectIterator.begin(); it != xObjectIterator.end(); ++it)
	{
		PdfObject obj = *(it->second);
		if (&obj && obj.IsDictionary())
		{
			PdfObject* pObjType = obj.GetDictionary().GetKey("Type");
			PdfObject* pObjSubType = obj.GetDictionary().GetKey("Subtype");

			if ((pObjType && pObjType->IsName() && (pObjType->GetName() == "XObject")) ||
				(pObjSubType && pObjSubType->IsName() && (pObjSubType->GetName() == "Image")))
			{
				width = obj.GetDictionary().FindKey("Width")->GetNumber();
				height = obj.GetDictionary().FindKey("Height")->GetNumber();

				if (dimensions.width() < width && dimensions.height() < height) {
					dimensions.setWidth(width);
					dimensions.setHeight(height);
				}
			}
		}
	}
	
	// check size
	if (dimensions.width() >= 1000 && dimensions.height() >= 1000) {
		out(ImageMetadata(dimensions));
		return ImageMetadataLoader::LOADED;
	} else if (dimensions.width() == 0 && dimensions.height() == 0) {
		return ImageMetadataLoader::NO_IMAGES;
	} else {
		return ImageMetadataLoader::IMAGE_TOO_SMALL;
	}
	return ImageMetadataLoader::GENERIC_ERROR;
}

bool PdfReader::seemsLikePdf(QFile & file)
{
	// first few bytes of a pdf file: "%PDF-1."
	const char start_header[] = "\x25\x50\x44\x46\x2D\x31\x2E";
	char buffer[8];

	qint64 seen = file.peek(buffer, 8);
	return	(seen >= 7 && memcmp(buffer, start_header, 7) == 0);
}

QImage
PdfReader::readImage(QFile& file, int const page_num)
{
	PdfMemDocument pdfDoc;
	pdfDoc.Load(file.fileName().toStdString());
	// get page
	auto& pPage = pdfDoc.GetPages().GetPageAt(page_num);

	// stores the image to extract; only the largest one on the page is chosen
	PdfObject * pdfImage = nullptr;
	QSize dimensions(0, 0);
	qint64 width = 0;
	qint64 height = 0;
	
	// go through all resources on the page and extract dimensions of each image
	auto pResources = pPage.GetResources();
	if (!pResources) {
		return QImage();
	}

	auto xObjectIterator = pResources->GetResourceIterator(PdfResourceType::XObject);

	for (auto it = xObjectIterator.begin(); it != xObjectIterator.end(); ++it)
	{
		PdfObject obj = *(it->second);
		if (&obj && obj.IsDictionary()) {
			PdfObject* pObjType = obj.GetDictionary().GetKey("Type");
			PdfObject* pObjSubType = obj.GetDictionary().GetKey("Subtype");

			if ((pObjType && pObjType->IsName() && (pObjType->GetName() == "XObject")) ||
				(pObjSubType && pObjSubType->IsName() && (pObjSubType->GetName() == "Image")))
			{

				width = obj.GetDictionary().FindKey("Width")->GetNumber();
				height = obj.GetDictionary().FindKey("Height")->GetNumber();

				// Save/replce image, if it bigger than previous image
				if (dimensions.width() < width && dimensions.height() < height) {
					dimensions.setWidth(width);
					dimensions.setHeight(height);
					pdfImage = &obj;
				}
			}
		}
	}

	QImage image;

	// extract image and set correct metadata
	if (pdfImage && dimensions.width() >= 1000 && dimensions.height() >= 1000) {
		// We'll just try to get the binary stream into a QIODevice and send it through ImageLoader::load
		auto pStream = pdfImage->GetStream()->GetCopy();
		QByteArray imageBuffer(pStream.data(), pStream.size());
		QDataStream newImage(imageBuffer);

		QImageReader(newImage.device()).read(&image);
		return image;
	} else {
		// image is too small or no images found on page
		return QImage();
	}

	return QImage();
}

