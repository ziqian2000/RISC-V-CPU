#include "io.h"

int N;
int h = 99;
int i = 100;
int j = 101;
int k = 102;
int total = 0;

int main() {
  	int a;
    int b;
	int c;
	// N=inl();
	N = 20;
	for ( a=1; a<=N; a++ )
	for ( b=1; b<=N; b++ )
	for ( c=1; c<=N; c++ )
		total += a * h + b * i + c * j;
	
	outlln(total);
	// printf("%d\n",total);
	return 0;
}
