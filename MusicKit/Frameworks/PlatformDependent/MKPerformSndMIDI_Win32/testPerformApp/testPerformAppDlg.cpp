// testPerformAppDlg.cpp : implementation file
//

#include "stdafx.h"
#include "testPerformApp.h"
#include "testPerformAppDlg.h"
typedef int port_t;
//#include "/Local/Developer/Frameworks/MKPerformSndMIDI.framework/Headers/midi_driver.h"
#include "/tomandandy/PublicDomain/MusicKit/Frameworks/PlatformDependent/MKPerformMIDI_Win32/mididriver_types.h"
#include "/tomandandy/PublicDomain/MusicKit/Frameworks/PlatformDependent/MKPerformMIDI_Win32/mididriverUser.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppDlg dialog

CTestPerformAppDlg::CTestPerformAppDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CTestPerformAppDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CTestPerformAppDlg)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CTestPerformAppDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CTestPerformAppDlg)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CTestPerformAppDlg, CDialog)
	//{{AFX_MSG_MAP(CTestPerformAppDlg)
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_PLAY, OnPlay)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppDlg message handlers

BOOL CTestPerformAppDlg::OnInitDialog()
{
//  int size;
//  unsigned int patches[] = {1, 4, 0, 0x200034};

  CDialog::OnInitDialog();

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

  	// TODO: Add extra initialization here
//	MDBecomeOwner(0, 0);
//  MDClaimUnit(0, 0, 2);
//  MIDIDownloadDLSInstruments(patches, 4);
//  MDSetClockQuantum(0, 0, 1000);
//  MDSetClockMode(0, 0, 0, 0);
//  MDGetAvailableQueueSize (0, 0, 0, &size);
//  MDStopClock()
//  MDSetClockTime(0, 0, time);
//  MDSetClockTime(0, 0, 0);
//  MDStartClock(0, 0);


	return TRUE;  // return TRUE  unless you set the focus to a control
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CTestPerformAppDlg::OnPaint() 
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, (WPARAM) dc.GetSafeHdc(), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CTestPerformAppDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}

void CTestPerformAppDlg::OnPlay() 
{
  int i;
  MDRawEvent sequence[4];
  int time = 600;
  int midiChan = 1;
  int size;
  unsigned int patches[] = {1, 4, 0, 0x200034};

  // TODO: Add extra initialization here
	MDBecomeOwner(0, 0);
  MDClaimUnit(0, 0, 6);
  MIDIDownloadDLSInstruments(patches, 4);
  MDSetClockQuantum(0, 0, 1000);
  MDSetClockMode(0, 0, 0, 0);
  MDGetAvailableQueueSize (0, 0, 0, &size);
//  MDStopClock()
  MDSetClockTime(0, 0, time);
//  MDSetClockTime(0, 0, 0);
  MDStartClock(0, 0);

  for(i = 0; i < 42; i++) {
    sequence[0].time = sequence[1].time = sequence[2].time = time;
    if(i == 0) { // send a patch change
      sequence[0].byte = 0xc0 + midiChan;
      sequence[1].byte = 0x01; // change to patch 1
      time += 20; // a little bit of breathing time
    } 
    else if(i == 20) { // send a patch change
      sequence[0].byte = 0xc0 + midiChan;
      sequence[1].byte = 0x04; // change to patch 4
      time += 20; // a little bit of breathing time
    }
    else {
      sequence[0].byte = 0x90 + midiChan; 
      if(i % 2 == 0) {
        sequence[1].byte = 0x20 + i;
        sequence[2].byte = 0x78;
      }
      else {
        sequence[1].byte = 0x1F + i;
        sequence[2].byte = 0x00;
      }
      time += 500;
    }
    MDSendData(0, 0, 0, sequence, 3); // note-on, encoded for a little-endian representation	
  }
}
