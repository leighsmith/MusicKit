// testPerformAppDlg.h : header file
//

#if !defined(AFX_TESTPERFORMAPPDLG_H__57533766_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_)
#define AFX_TESTPERFORMAPPDLG_H__57533766_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

/////////////////////////////////////////////////////////////////////////////
// CTestPerformAppDlg dialog

class CTestPerformAppDlg : public CDialog
{
// Construction
public:
	CTestPerformAppDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CTestPerformAppDlg)
	enum { IDD = IDD_TESTPERFORMAPP_DIALOG };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTestPerformAppDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CTestPerformAppDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnPlay();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_TESTPERFORMAPPDLG_H__57533766_4927_11D3_93E2_00A0CC26DBF7__INCLUDED_)
