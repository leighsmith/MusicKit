// While gdb is also present on Windows, the mach headers aren't.
#ifndef WIN32

#import <stdio.h>
#import <mach/mach.h>
#import <mach/exception.h>
#import <mach/mach_error.h>
#import <mach/exc_server.h>
#import <mach/cthreads.h>
#import <mach/mig_errors.h>

typedef struct {
    mach_port_t old_exc_port;
    mach_port_t clear_port;
    mach_port_t exc_port;
} ports_t;

volatile boolean_t pass_on = FALSE;

static any_t exc_thread(ports_t *port_p)
{
    kern_return_t r;
    char *msg_data[2][64];
    mach_msg_header_t *imsg = (mach_msg_header_t *)msg_data[0],
    *omsg = (mach_msg_header_t *)msg_data[1];
    
    /* Wait for exceptions */
    while(1) {
	imsg->msgh_size = 64;
	imsg->msgh_local_port = port_p->exc_port;
	r = msg_receive(imsg, MSG_OPTION_NONE, 0);
	if (r == RCV_SUCCESS) {
	    /* Give the message to the Mach exception server. */
	    if (exc_server(imsg,omsg)) {
		/* send the reply message that exc_serv gave us. */
		r = msg_send(omsg, MSG_OPTION_NONE, 0);
		if (r != SEND_SUCCESS) {
		    mach_error("exc_thread msg_send",r);
		    exit(1);
		}
	    }
	    else {
		/* exc_server refused to handle the imsg. */
		exit(2);
	    }
	}
	else {
	    /* msg_receive returned an error. */
	    mach_error("exc_thread msg_receive",r);
	    exit(3);
	}
	
	/* Pass the message to the old exception handler, if necessary. */
	if (pass_on == TRUE) {
	    imsg->msgh_remote_port = port_p->old_exc_port;
	    imsg->msgh_local_port = port_p->clear_port;
	    r = msg_send(imsg, MSG_OPTION_NONE, 0);
	    if (r != SEND_SUCCESS) {
		mach_error("msg_send to old_exc_port",r);
		exit(4);
	    }
	}
    }
}

static boolean_t bailOut = FALSE;

/* catch_exception_raise() is called by the exc_server(). */
// This needs to be defined with traditional port_t types to stop the compiler complaining...
kern_return_t catch_exception_raise(port_t exception_port,
				    port_t thread, port_t task, int exception, int code, int subcode)
{
    /* decide here what to ignore and what to pass on */
    switch(exception) {
      case EXC_BREAKPOINT:
	pass_on = TRUE;
	break;
      case EXC_BAD_ACCESS:
	bailOut = TRUE;
      case EXC_BAD_INSTRUCTION:
      case EXC_ARITHMETIC:
      case EXC_EMULATION:
      case EXC_SOFTWARE:
	pass_on = FALSE;
	break;
    }
//    mach_NeXT_exception("catch_exception_raise",exception,code,subcode);

     return KERN_SUCCESS;
}


static ports_t ports = {PORT_NULL};

#if 0  // redundant, commented out LMS
static void setExceptionThread(void)
{
    kern_return_t r;
//    char *nullAddr = NULL;
    
    bailOut = FALSE;
    /* save the old exception port for this task */
    r = task_get_exception_port(task_self(), &(ports.old_exc_port));
    if (r != KERN_SUCCESS) {
	mach_error("task_get_exception_port",r);
	exit(1);
    }
    
    if (!ports.exc_port) {
	/* create a new exception port for this task */
	r = port_allocate(task_self(), &(ports.exc_port));
	if (r != KERN_SUCCESS) {
	    mach_error("port_allocate",r);
	    exit(1);
	}
	/* Fork the thread that listens to the exception port. */
	cthread_detach(cthread_fork((cthread_fn_t)exc_thread,(any_t)&ports));
	ports.clear_port = thread_reply();
    }

    /* install the new exception port for this task */
    r = task_set_exception_port(task_self(), (ports.exc_port));
    if (r != KERN_SUCCESS) {
	mach_error("task_set_exception_port",r);
	exit(1);
    }
    
}

static void restoreExceptionThread(void)
{
    /* install the old port again */
    kern_return_t r = task_set_exception_port(task_self(), (ports.old_exc_port));
    if (r != KERN_SUCCESS) {
	mach_error("task_set_exception_port",r);
	exit(1);
    }
}
#endif

#endif