; Created by https://github.com/PolicyPuma4
; Repository https://github.com/PolicyPuma4/ShadowPlay-resolution

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Menu, Tray, Icon, Icons\display_record_icon16.png

Games := []
Games["DeadByDaylight-Win64-Shipping.exe"] := {"Width": 1600, "Height": 1080}

SleepTime := 15000
RecordingWindow := ""

Auth := GetSecurity(SleepTime)

Loop
{
  if (A_Index > 1)
    Sleep SleepTime

  if RecordingWindow
  {
    if not WinExist("ahk_id " RecordingWindow)
      RecordingWindow := ""
    continue
  }

  WinGet, WindowID, ID, A
  WinGet, ProcessName, ProcessName, ahk_id %WindowID%
  WinGetPos,,, Width, Height, ahk_id %WindowID%

  for Key, Value in Games
  {
    if (ProcessName = Key)
    {
      if (Width = Value["Width"] and Height = Value["Height"])
      {
        if not PostInstantReplayEnable(Auth, false)
        {
          Auth := GetSecurity(SleepTime)
          break
        }
        if not PostInstantReplayEnable(Auth, true)
        {
          Auth := GetSecurity(SleepTime)
          break
        }
        if GetInstantReplayEnable(Auth)["Response"]
          RecordingWindow := WindowID
      }
      break
    }
  }
}


GetSecurity(SleepTime)
{
  Loop
  {
    if (A_Index > 1)
      Sleep SleepTime

    FILE_MAP_READ := 4
    ; Opens a named file mapping object
    hMapFile := DllCall("OpenFileMapping", "Ptr", FILE_MAP_READ, "Int", 0, "Str", "{8BA1E16C-FC54-4595-9782-E370A5FBE8DA}")
    if not hMapFile
      continue
    ; Maps a view of a file mapping into the address space of a calling process
    pBuf := DllCall("MapViewOfFile", "Ptr", hMapFile, "Int", FILE_MAP_READ, "Int", 0, "Int", 0)
    if not pBuf
      continue
    ; Copies a string from a memory address
    String := StrGet(pBuf,, Encoding := "UTF-8")
    ; Unmaps a mapped view of a file from the calling process's address space
    DllCall("UnmapViewOfFile", "Ptr", pBuf)
    ; Closes an open object handle
    DllCall("CloseHandle", "Ptr", hMapFile)

    Parsed := StrSplit(Trim(String, "{" "}"), ",", """port"":" """secret"":")
    return {"Port": Parsed[1], "Secret": Parsed[2]}
  }
}


GetInstantReplayEnable(Auth)
{
  try
  {
    Connection := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    Connection.Open("GET", "http://localhost:" Auth["Port"] "/ShadowPlay/v.1.0/InstantReplay/Enable", true)
    Connection.SetRequestHeader("X_LOCAL_SECURITY_COOKIE", Auth["Secret"])
    Connection.Send()
    Connection.WaitForResponse()
    Response := Connection.ResponseText
    ResponseStatus := Connection.Status
    if not (Connection.Status = 200)
      return
    if (Response = "{""status"":false}")
      return {"Response": false}
    if (Response = "{""status"":true}")
      return {"Response": true}
  }
  catch
    return
}


PostInstantReplayEnable(Auth, State)
{
  if State
    State := "true"
  else
    State := "false"

  try
  {
    Connection := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    Connection.Open("POST", "http://localhost:" Auth["Port"] "/ShadowPlay/v.1.0/InstantReplay/Enable", true)
    Connection.SetRequestHeader("X_LOCAL_SECURITY_COOKIE", Auth["Secret"])
    Connection.SetRequestHeader("Content-Type", "application/json")
    Connection.Send("{""status"": " State "}")
    Connection.WaitForResponse()
    ResponseStatus := Connection.Status
    if not (Connection.Status = 200)
      return
    return {"Response": true}
  }
  catch
    return
}
