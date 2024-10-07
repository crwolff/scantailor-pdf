/*
    Scan Tailor - Interactive post-processing tool for scanned pages.
    Copyright (C) 2008-2017 Joseph Artsimovich <joseph.artsimovich@gmail.com>
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

#include "PdfReader.h"
#include "ImageMetadata.h"
#include "ImageLoader.h"
#include <QIODevice>
#include <QImage>
#include <QFile>
#include <QByteArray>

ImageMetadataLoader::Status
PdfReader::readMetadata(QIODevice& device,
	VirtualFunction1<void, ImageMetadata const&>& out)
{
	QByteArray buffer(device.readAll());
	PdfMemDocument pdfDoc;
	pdfDoc.Load(buffer.constData());

	QSize dimensions(0, 0);
	qint64 width = 0;
	qint64 height = 0;

	for (auto obj : pdfDoc.GetObjects())
	{
		if (obj->IsDictionary())
		{
			PdfObject* pObjType = obj->GetDictionary().GetKey("Type");
			PdfObject* pObjSubType = obj->GetDictionary().GetKey("Subtype");

			if ((pObjType && pObjType->IsName() && (pObjType->GetName() == "XObject")) ||
				(pObjSubType && pObjSubType->IsName() && (pObjSubType->GetName() == "Image")))
			{
				width = obj->GetDictionary().FindKey("Width")->GetNumber();
				height = obj->GetDictionary().FindKey("Height")->GetNumber();

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

bool PdfReader::seemsLikePdf(QIODevice & device)
{
	// first few bytes of a pdf file: "%PDF-1."
	const char start_header[] = "\x25\x50\x44\x46\x2D\x31\x2E";
	char buffer[8];

	qint64 seen = device.peek(buffer, 8);
	return	(seen >= 7 && memcmp(buffer, start_header, 7) == 0);
}

QImage
PdfReader::readImage(QIODevice& device, int const page_num)
{
	QByteArray buffer(device.readAll());
	PdfMemDocument pdfDoc;
	pdfDoc.Load(buffer.constData());

	// stores the image to extract; only the largest one on the page is chosen
	PdfObject * pdfImage = nullptr;
	QSize dimensions(0, 0);
	qint64 width = 0;
	qint64 height = 0;

	for (auto obj : pdfDoc.GetObjects())
	{
		if (obj->IsDictionary())
		{
			PdfObject* pObjTypePage = obj->GetDictionary().GetKey("Type");

			if (pObjTypePage && pObjTypePage->IsName() && (pObjTypePage->getName() == "Page"))
			{
				PdfObject* pObjType = obj->GetDictionary().GetKey("Type");
				PdfObject* pObjSubType = obj->GetDictionary().GetKey("Subtype");

				if ((pObjType && pObjType->IsName() && (pObjType->GetName() == "XObject")) ||
					(pObjSubType && pObjSubType->IsName() && (pObjSubType->GetName() == "Image")))
				{
					width = obj->GetDictionary().FindKey("Width")->GetNumber();
					height = obj->GetDictionary().FindKey("Height")->GetNumber();

					if (dimensions.width() < width && dimensions.height() < height) {
						dimensions.setWidth(width);
						dimensions.setHeight(height);
					}
				}
			}
		}
	}


	// go through all references and extract dimensions of each image
	for (auto pObj : pPage.GetResources().GetObject())
	{
		if (pObj.isDictionary()) {
			PdfObject* pObjType = obj->GetDictionary().GetKey("Type");
			PdfObject* pObjSubType = obj->GetDictionary().GetKey("Subtype");

			if ((pObjType && pObjType->IsName() && (pObjType->GetName() == "XObject")) ||
				(pObjSubType && pObjSubType->IsName() && (pObjSubType->GetName() == "Image")))
			{

				width = obj->GetDictionary().FindKey("Width")->GetNumber();
				height = obj->GetDictionary().FindKey("Height")->GetNumber();

				// Replace image, if it bigger than previous image
				if (dimensions.width() < width && dimensions.height() < height) {
					dimensions.setWidth(width);
					dimensions.setHeight(height);
					pdfImage = pObj;
				}
			}
		}
	}



	QImage image;

	// extract image and set correct metadata
	if (pdfImage && dimensions.width() >= 1000 && dimensions.height() >= 1000) {
		// We'll just try to get the binary stream into a QIODevice and send it through ImageLoader::load
		auto pStream = pdfImage->GetStream()->GetCopy();
		QByteArray imageBuffer(pStream.data(); pStream.size());
		QDataStream newImage(imageBuffer);

		return ImageLoader::load(*newImage.device(), 0);

	} else {
		// image is too small or no images found on page
		return QImage();
	}

	return QImage();
}

