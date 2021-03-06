{
Copyright (C) 2002-2004  Massimo Melina (www.rejetto.com)

This file is part of &RQ.

    &RQ is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    &RQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with &RQ; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
unit smsDlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, RnQButtons;

type
  TsmsFrm = class(TForm)
    msgBox: TMemo;
    Label1: TLabel;
    destBox: TMemo;
    Label2: TLabel;
    SendBtn: TRnQSpeedButton;
    charsBox: TLabeledEdit;
    delivery_receiptBox: TCheckBox;
    procedure SendBtnClick(Sender: TObject);
    procedure msgBoxChange(Sender: TObject);
  public
    constructor doAll(owner_ :Tcomponent; msg,dest:string);
  end;

//var
//  smsFrm: TsmsFrm;

implementation

uses
  globalLib, utilLib, langLib, RQGlobal, RQThemes, RQUtil;

{$R *.dfm}

constructor TsmsFrm.doAll(owner_ :Tcomponent; msg,dest:string);
begin
inherited create(owner_);
position:=poDefaultPosOnly;
  theme.pic2ico(PIC_SMS, icon);
msgBox.text:=msg;
destBox.text:=dest;
translateWindow(self);
showForm(self);
bringForeground:=handle;
msgBoxChange(nil);
end;

procedure TsmsFrm.SendBtnClick(Sender: TObject);
var
  i : Integer;
begin
// OnlFeature;
 for i := 1 to destBox.Lines.Count do
  ICQ.sendSMS(destBox.Lines[i], msgBox.Text, delivery_receiptBox.Checked);
end;

procedure TsmsFrm.msgBoxChange(Sender: TObject);
begin
  charsBox.text:=intToStr(length(msgBox.Text));
end;

end.
