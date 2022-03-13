#ifndef FOUNDATION_CONFIG_H_
#define FOUNDATION_CONFIG_H_

#include <QtGlobal>

#if defined(SHARED_FOUNDATION)
#	if defined(BUILDING_FOUNDATION)
#		define FOUNDATION_EXPORT Q_DECL_EXPORT
#	else
#		define FOUNDATION_EXPORT Q_DECL_IMPORT
#	endif
#else	// Static build: Don't export Symbols
#	define FOUNDATION_EXPORT
#endif

#endif
