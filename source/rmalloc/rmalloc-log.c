#include <unistd.h>

#include "replace_malloc.h"
#include "logger.h"

static const malloc_table_t *funcs = NULL;

void replace_init(const malloc_table_t *table)
{
	write(1, "replace_init\n", 13);
	funcs = table;
}

void *replace_malloc(size_t size)
{
	void *ptr = funcs->malloc(size);
	doLog(MALLOC, ptr, size);
	return ptr;
}

void *replace_calloc(size_t num, size_t size)
{
	void *ptr = funcs->calloc(num, size);
	doLog(MALLOC, ptr, num*size);
	return ptr;
}

void *replace_realloc(void *ptr, size_t size)
{
	doLog(FREE, ptr, 0);
	ptr = funcs->realloc(ptr, size);
	doLog(MALLOC, ptr, size);
	return ptr;
}

void replace_free(void *ptr)
{
	doLog(FREE, ptr, 0);
	funcs->free(ptr);
}

void *replace_memalign(size_t alignment, size_t size)
{
	void *ptr = funcs->memalign(alignment, size);
	doLog(MALLOC, ptr, size);
	return ptr;
}

int replace_posix_memalign(void **ptr, size_t alignment, size_t size)
{
	int ret = funcs->posix_memalign(ptr, alignment, size);
	doLog(MALLOC, *ptr, size);
	return ret;
}

void *replace_aligned_alloc(size_t alignment, size_t size)
{
	void *ptr = funcs->aligned_alloc(alignment, size);
	doLog(MALLOC, ptr, size);
	return ptr;
}

void *replace_valloc(size_t size)
{
	void *ptr = funcs->valloc(size);
	doLog(MALLOC, ptr, size);
	return ptr;
}

size_t replace_malloc_usable_size(usable_ptr_t ptr)
{
	return funcs->malloc_usable_size(ptr);
}

size_t replace_malloc_good_size(size_t size)
{
	return funcs->malloc_good_size(size);
}