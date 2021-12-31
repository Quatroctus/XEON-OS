#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

int main(int argc, char** args) {
    FILE* fp = fopen("./bin/boot", "r+");
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    
    assert(size < 510 && "Bootsector is limited to 512 bytes.");

    fprintf(stderr, "Bootsector is %li bytes long.\n", size);

    char block[510 - size];
    unsigned short flag = 0xAA55;
    memset(block, 0, 510 - size);
    fwrite(block, 1, 510 - size, fp);
    fwrite(&flag, 1, 2, fp);

    fclose(fp);

    return 0;
}
