unit Unit1;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ScrollBox,
  FMX.Memo;

type
  TMyPanel = class(TPanel)
  const
    GRAB_SIZE: Integer = 3;
    A = 55.229;
    LINE_COUNT = 4;
    PointArray: array [0 .. LINE_COUNT * 3 - 1] of TPointF = ((X: 200; Y: 100), // 始点
      (X: 200 + A; Y: 100), (X: 300; Y: 200 - A), (X: 300; Y: 200), // 右上
      (X: 300; Y: 200 + A), (X: 255; Y: 300), (X: 200; Y: 300), // 右下
      (X: 200 - A; Y: 300), (X: 100; Y: 200 + A), (X: 100; Y: 200), // 左下
      (X: 100; Y: 200 - A), (X: 200 - A; Y: 100) // 左上
      );
  private
    FPointNumber: Integer;
    FMoveFlag: Boolean;
    FSelectionPoint: array [0 .. LINE_COUNT * 3 - 1] of TSelectionPoint;
    procedure PanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  protected
    procedure DoPaint; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { private 宣言 }
  public
    { public 宣言 }
    MyPanel: TMyPanel;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
{ TMyPanel }

procedure TForm1.FormCreate(Sender: TObject);
begin
  MyPanel := TMyPanel.Create(Self);
  MyPanel.Parent := Self;
  MyPanel.Position.X := 10;
  MyPanel.Position.Y := 10;
  MyPanel.Width := Self.ClientWidth - 20;
  MyPanel.Height := Self.ClientHeight - 20;
  MyPanel.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];
end;

{ TMyPanel }

constructor TMyPanel.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited;
  Self.FPointNumber := -1;
  Self.FMoveFlag := False;
  Self.OnMouseDown := Self.PanelMouseDown;
  Self.OnMouseUp := Self.PanelMouseUp;
  Self.OnMouseMove := Self.PanelMouseMove;

  for I := 0 to Length(Self.FSelectionPoint) - 1 do
  begin
    FSelectionPoint[I] := TSelectionPoint.Create(Self);
    FSelectionPoint[I].Parent := Self;
    FSelectionPoint[I].Position.X := PointArray[I].X;
    FSelectionPoint[I].Position.Y := PointArray[I].Y;
    FSelectionPoint[I].Width := 3;
    FSelectionPoint[I].Height := 3;
    FSelectionPoint[I].HitTest := False;
  end;
end;

procedure TMyPanel.DoPaint;
var
  Path: TPathData;
  Line: TPathData;
  I: Integer;
begin
  inherited;

  Path := TPathData.Create;
  Path.MoveTo(Self.FSelectionPoint[0].Position.Point);
  for I := 0 to LINE_COUNT - 1 do
  begin
    if I * 4 >= Length(Self.FSelectionPoint) then
      Path.CurveTo(
        Self.FSelectionPoint[I * 3 + 1].Position.Point,
        Self.FSelectionPoint[I * 3 + 2].Position.Point,
        Self.FSelectionPoint[0].Position.Point)
    else
      Path.CurveTo(
        Self.FSelectionPoint[I * 3 + 1].Position.Point,
        Self.FSelectionPoint[I * 3 + 2].Position.Point,
        Self.FSelectionPoint[I * 3 + 3].Position.Point)
  end;
  Path.ClosePath;

  Canvas.BeginScene;
  Canvas.Stroke.Color := TAlphaColorRec.Blue;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := 1;
  Canvas.DrawPath(Path, 1.0);

  Canvas.Stroke.Color := TAlphaColorRec.Black;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Dash := TStrokeDash.Dot;
  Canvas.Stroke.Thickness := 1;
  for I := 0 to LINE_COUNT - 1 do
  begin
    Line := TPathData.Create;
    Line.MoveTo(Self.FSelectionPoint[I * 3].Position.Point);
    Line.LineTo(Self.FSelectionPoint[I * 3 + 1].Position.Point);
    Canvas.DrawPath(Line, 1.0);
    Line.Free;

    Line := TPathData.Create;
    Line.MoveTo(Self.FSelectionPoint[I * 3 + 2].Position.Point);
    if I * 4 >= Length(Self.FSelectionPoint) then
      Line.LineTo(Self.FSelectionPoint[0].Position.Point)
    else
      Line.LineTo(Self.FSelectionPoint[I * 3 + 3].Position.Point);
    Canvas.DrawPath(Line, 1.0);
    Line.Free;
  end;

  Canvas.EndScene;
  Path.Free;
end;

procedure TMyPanel.PanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    Self.FMoveFlag := True;
  end;
end;

procedure TMyPanel.PanelMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  ARect: TRectF;
  I: Integer;
begin
  if Self.FMoveFlag then
  begin
    if Self.FPointNumber = -1 then
      Exit;
    Self.FSelectionPoint[Self.FPointNumber].Position.X := X;
    Self.FSelectionPoint[Self.FPointNumber].Position.Y := Y;
    Repaint;
  end
  else
  begin
    Self.FPointNumber := -1;

    for I := 0 to Length(Self.FSelectionPoint) - 1 do
    begin
      ARect := RectF(
        Self.FSelectionPoint[I].Position.X - GRAB_SIZE - 1,
        Self.FSelectionPoint[I].Position.Y - GRAB_SIZE - 1,
        Self.FSelectionPoint[I].Position.X + GRAB_SIZE + 1,
        Self.FSelectionPoint[I].Position.Y + GRAB_SIZE + 1);

      if PtInRect(ARect, PointF(X, Y)) then
        Self.FPointNumber := I;
    end;
  end;
end;

procedure TMyPanel.PanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Self.FMoveFlag := False;
end;

end.
