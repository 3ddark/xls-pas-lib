//****************************************************************
// zexml.inc - Global compiler directives
// Modernized for Delphi 10.4 Sydney and above
// Target: Delphi 10.4+ / Win32 / Win64
// ZIP: System.Zip (built-in, no 3rd party needed)
// Encoding: UTF-8 (TEncoding.UTF8)
//****************************************************************

// ZColorStringGrid component - not needed for pure library use
{$DEFINE NOZCOLORSTRINGGRID}

// Conditional formatting support
{$DEFINE ZUSE_CONDITIONAL_FORMATTING}

// Compact XML output (no indents/newlines) - smaller file size
{$DEFINE NOXMLINDENTS}

// Chart support
{$DEFINE ZUSE_CHARTS}

// Drawing/image support
{$DEFINE ZUSE_DRAWINGS}

// ZIP backend: System.Zip (Delphi XE8+, built-in, no external libs)
// Requires: Delphi 10.4 Sydney or above
{$DEFINE SYSTEMZIP}

// Free Pascal / Lazarus is NOT supported in this modernized version
// Use the original ZEXMLSS for FPC/Lazarus support
{$IFDEF FPC}
  {$MESSAGE FATAL 'This modernized version targets Delphi 10.4+ only. Use original ZEXMLSS for FPC/Lazarus.'}
{$ENDIF}

// Require minimum Delphi 10.4 (CompilerVersion 34.0)
{$IF CompilerVersion < 34.0}
  {$MESSAGE FATAL 'Delphi 10.4 Sydney or above required.'}
{$IFEND}
