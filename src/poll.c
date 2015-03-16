/*
 *  Written by xphh 2015 with 'MIT License'
 */
#include "src/poll.h"

C_API int socket_wait(int fd, int flag, int timeout)
{
	int flag_out = 0;
	struct pollfd pfd;

	tmpfd.events = 0;

	if (flag & READABLE)
	{
		pfd.events |= POLLIN;
	}
	if (flag & WRITABLE)
	{
		pfd.events |= POLLOUT;
	}

	if (poll(&pfd, 1, timeout) > 0)
	{
		if (pfd.revents & POLLIN)
		{
			flag_out |= READABLE;
		}

		if (pfd.revents & POLLOUT)
		{
			flag_out |= WRITABLE;
		}
	}

	return flag_out;
}
