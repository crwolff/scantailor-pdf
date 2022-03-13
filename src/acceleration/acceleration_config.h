#ifndef ACCELERATION_CONFIG_H_
#define ACCELERATION_CONFIG_H_

#include <QtGlobal>

#if defined(SHARED_ACCELERATION)
#	if defined(BUILDING_ACCELERATION)
#		define ACCELERATION_EXPORT Q_DECL_EXPORT
#	else
#		define ACCELERATION_EXPORT Q_DECL_IMPORT
#	endif
#else	// Static build: Don't export Symbols
#	define ACCELERATION_EXPORT
#endif

#endif
