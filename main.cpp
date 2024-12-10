#include <iostream>
#include "FuncA.h"
#include <sys/wait.h>

void sigchldHandler(int s)
{
	printf("Caught signal SIGCHLD\n");

	pid_t pid;
	int status;

	while ((pid = waitpid(-1,&status,WNOHANG)) > 0)
	{
		if (WIFEXITED(status)) printf("\nChild process terminated");
	}
}

void sigintHandler(int s)
{
	printf("Caught signal %d. Starting graceful exit procedure\n",s);

	pid_t pid;
	int status;
	while ((pid = waitpid(-1,&status,0)) > 0)
	{
		if (WIFEXITED(status)) printf("\nChild process terminated");
	}
	
	if (pid == -1) printf("\nAll child processes terminated");

	exit(EXIT_SUCCESS);
}

int CreateHTTPserver();
int main() {

    signal(SIGCHLD, sigchldHandler);
	signal(SIGINT, sigintHandler);
    
    TrigFunction trig;
    // std::cout << "FuncA result: " << trig.FuncA(0.5, 5) << std::endl;
    CreateHTTPserver();
    return 0;
}
