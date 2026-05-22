#include<stdio.h>
#include<string.h>
#include<unistd.h>
#include<time.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        return 1;
    }
    char path[256];
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    snprintf(path, sizeof(path), "/tmp/winebrowser-%ld%ld.txt", ts.tv_sec, ts.tv_nsec);
    FILE *f = fopen(path, "w");
    if (!f) {
        return 2;
    }
    fprintf(f,"%s",argv[1]);
    fclose(f);
    return 0;
}
