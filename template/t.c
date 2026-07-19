#define MEMSIZE 1024*50

#include "../lib/gui.h"
#include "../lib/fs.h"

void main()
{
	proc_info Form;

	@SetEventMask(EVM_REDRAW + EVM_KEY + EVM_BUTTON + EVM_MOUSE);
	loop() switch(WaitEvent())
	{
		case evMouse:			
			mouse.get();
			break;

		case evKey:
			@GetKeyScancode();
			if (AL == SCAN_CODE_ESC) @ExitProcess();
			break;

		case evReDraw:
			sc.get();
			DefineAndDrawWindow(100, 100, 300, 250, 0x34, sc.work, "Template app", 0);
			WriteText(10, 10, 0x90, sc.work_text, "Test");
			GetProcessInfo(#Form, SelfInfo);
	}
}
