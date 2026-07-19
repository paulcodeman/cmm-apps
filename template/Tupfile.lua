if tup.getconfig("NO_CMM") ~= "" then return end
tup.rule("t.c", "c-- /D=AUTOBUILD /D=$(C_LANG) /OPATH=%o %f" .. tup.getconfig("KPACK_CMD"), "t.com")
