#include<stdio.h>

int main(int argc, char *argv[]){
    FILE *f;
    if(argc!=2) return 1;
    f=fopen("C:\\smoke.txt","w");
    if(f==NULL) return 2;
    fprintf(f,"%s",argv[1]);
    fflush(f);
    fclose(f);
    return 0;
}
