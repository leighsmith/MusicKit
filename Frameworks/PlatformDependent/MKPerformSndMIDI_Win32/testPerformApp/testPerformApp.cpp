// testPerformApp.cpp : Defines the class behaviors for the application.
//

#include "stdafx.h"
#include "testPerformApp.h"
#include "testPerformAppDlg.h"
typedef int port_t;
#include "/tomandandy/PublicDomain/MusicKit/Frameworks/PlatformDependent/MKPerformMIDI_Win32/mididriver_types.h"
#include "/tomandandy/PublicDomain/MusicKit/Frameworks/PlatformDependent/MKPerformMIDI_Win32/mididriverUser.h"
//#include "../MKPerformMIDI/mididriver_types.h"
//#include "../MKPerformMIDI/mididriverUser.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppApp

BEGIN_MESSAGE_MAP(CTestPerformAppApp, CWinApp)
	//{{AFX_MSG_MAP(CTestPerformAppApp)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG
	ON_COMMAND(ID_HELP, CWinApp::OnHelp)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppApp construction

CTestPerformAppApp::CTestPerformAppApp()
{
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance
}

/////////////////////////////////////////////////////////////////////////////
// The one and only CTestPerformAppApp object

CTestPerformAppApp theApp;

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppApp initialization

BOOL CTestPerformAppApp::InitInstance()
{
	AfxEnableControlContainer();

	// Standard initialization
	// If you are not using these features and wish to reduce the size
	//  of your final executable, you should remove from the following
	//  the specific initialization routines you do not need.

#ifdef _AFXDLL
	Enable3dControls();			// Call this when using MFC in a shared DLL
#else
	Enable3dControlsStatic();	// Call this when linking to MFC statically
#endif

	CTestPerformAppDlg dlg;
	m_pMainWnd = &dlg;
	int nResponse = dlg.DoModal();
	if (nResponse == IDOK)
	{
		// TODO: Place code here to handle when the dialog is
		//  dismissed with OK
	}
	else if (nResponse == IDCANCEL)
	{
		// TODO: Place code here to handle when the dialog is
		//  dismissed with Cancel
	}

  MDStopClock (0, 1);
  // MDRequestQueueNotification called 0
  //MDRequestQueueNotification called 2016
  //MDAwaitReply called 9762296 timeout
  //MDClearQueue called
  //MDReleaseUnit called
  MDReleaseOwnership(0, 1);
	// Since the dialog has been closed, return FALSE so that we exit the
	//  application, rather than start the application's message pump.
	return FALSE;
}
