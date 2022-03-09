#ifndef DEWARPING_CONFIG_H_
#define DEWARPING_CONFIG_H_

#include <QtGlobal>

#if defined(SHARED_DEWARPING)
#	if defined(BUILDING_DEWARPING)
#		define DEWARPING_EXPORT Q_DECL_EXPORT
#	else
#		define DEWARPING_EXPORT Q_DECL_IMPORT
#	endif
#else	// Static build: Don't export Symbols
#	define DEWARPING_EXPORT
#endif

#endif
