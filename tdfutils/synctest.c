#include<unistd.h>
#include<fcntl.h>
#include<errno.h>
int main(){
    int ntsync=open("/dev/ntsync",O_RDWR);
    if (ntsync!=-1) {
        close(ntsync);
        return 2;
    }
    if(syscall(449,0,0,0,0,0)==-1){
        return errno==ENOSYS?0:1;
    }else{
        return 1;
    }
}
