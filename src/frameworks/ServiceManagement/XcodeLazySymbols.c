#include <ServiceManagement/ServiceManagement.h>

XPC_EXPORT Boolean SMJobIsEnabled(CFStringRef domain, CFStringRef jobLabel)
{
	(void)domain;
	(void)jobLabel;
	return false;
}
