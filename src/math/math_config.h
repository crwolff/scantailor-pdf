#ifndef MATH_CONFIG_H_
#define MATH_CONFIG_H_

#include <QtGlobal>

#if defined(SHARED_MATH)
#	if defined(BUILDING_MATH)
#		define MATH_EXPORT Q_DECL_EXPORT
#	else
#		define MATH_EXPORT Q_DECL_IMPORT
#	endif
#else	// Static build: Don't export Symbols
#	define MATH_EXPORT
#endif

#endif
