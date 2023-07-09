#include<unistd.h>
#include<errno.h>
int main(){
    if(syscall(449,0,0,0,0,0)==-1){
        return errno==ENOSYS?0:1;
    }else{
        return 0;
    }
}
