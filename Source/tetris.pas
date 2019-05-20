{$D-,L-,Y-,S-,R-,E-,N+,G+,W-,I-,B-}
uses crt,os2;
type fig=array[1..4,1..4] of word;
var glass:array[1..19,1..12] of word;
    i,j,x,y,rotare,level,count:integer;
    score{,nextTIME}:longint;
    figCUR,figNEXT:word;
    ch:char;
    linedone:boolean;
    SemHandle,TimerHandle:Longint;

const ofs_y      = 1;
      TIMER_MUL  =24;
      maxrec:word= 0;

{$I tetris.inc}

procedure print;
begin
  TextBackground(7);
  TextColor(1);
  for i:=1 to 19 do
  begin
    gotoxy(10,i+ofs_y);
    write('²');
    for j:=1 to 12 do
      if glass[i,j]=1 then write('')
                      else write('ÛÛ');
    write('²');
  end;
  for i:=1 to 4 do
    for j:=1 to 4 do
      if rot[figCUR,rotare,i,j]=1 then
      begin
        gotoxy((x+j)*2+9,y+i+ofs_y);
        writeln('**');
      end;
  gotoxy(10,20+ofs_y);
  for i:=1 to 13 do write('²²');
  TextBackground(0);
  TextColor(6);
  gotoxy(60,14);writeln('Record: ',maxrec,'      ');
  TextColor(5);
  gotoxy(60,11);writeln('Score : ',Score,'      ');
  gotoxy(60,10);writeln('Level : ',level,'      ');
  gotoxy(60,2);writeln('NEXT:');
  for i:=1 to 4 do
  begin
    gotoxy(60,2+i);
    for j:=1 to 4 do
      if rot[fignext,1,i,j]=1 then write('ÛÛ')
                              else write('  ');
  end;
end;

procedure init;
var FF:File;
begin
  assign(FF,'tetris.res');
  reset(FF,1);
  if ioresult=0 then
  begin
    blockread(FF,maxrec,2);
    close(FF);
  end;
  {nosound;}
  TextBackground(0);
  TextColor(2);level:=1;
  fignext:=$ff;randomize;
  score:=0;
  fillchar(glass,sizeof(glass),0);
  GenNew; print;
end;

function ok:boolean;
 begin
  ok:=false;
  for i:=1 to 4 do
    for j:=1 to 4 do
      if (rot[figCUR,rotare,i,j]=1) and 
        ((i+y>19)or(j+x>12)or(j+x=0) or (glass[i+y,j+x]=1)) then exit;
  ok:=true; print
end;

procedure run;
begin
  repeat
    if keypressed then
    begin
      ch:=readkey;
      if ch=#0 then ch:=readkey;
      case ord(ch) of
      {up}
        72:begin
           rotare:=(rotare) mod 4+1;
           if not ok then rotare:=(rotare+3) mod 4;
         end;
      {left}
        75:begin
           dec(x);
           if not ok then inc(x);
         end;
      {rigth}
        77:begin
           inc(x);
           if not ok then dec(x);
         end;
      {down}
        32,80:begin
           repeat
             inc(y);
           until not ok;
           dec(y);
         end;
      {escape}
        27:begin
          if score>maxrec then maxrec:=score;
          exit;
        end;
      end;
    end;

{    DosBeep(2000,1);}

    if DosSemWait(SemHandle,10)=0 then
    begin
      inc(y);
      if not ok then
      begin
        dec(y);
        for i:=1 to 4 do
          for j:=1 to 4 do
            if rot[figCUR,rotare,i,j]=1 then glass[i+y,j+x]:=1;
        count:=0; i:=1;
        while i<20 do
        begin
          linedone:=true;
          for j:=1 to 12 do
            if glass[i,j]=0 then
            begin
              linedone:=false;break;
            end;
          if linedone then
          begin
            for j:=1 to 24 do
            begin
              {DosBeep(200+j*10,1);}
              for ch:=#32 to #255 do
              begin
                gotoxy(j+10,i+ofs_y);
                write(ch);
              end;
            end;
            {nosound;}
            move(glass[1],glass[2],sizeof(glass[1])*(i-1));
            print;
            i:=1;inc(count);
          end;
          inc(i);
        end;
        case count of
          0:inc(score,1);
          1:inc(score,10);
          2:inc(score,40);
          3:inc(score,80);
          4:inc(score,100);
        end;
        level:=score div 500+1;
        GenNew;
        if not ok then
        begin
          if score>maxrec then maxrec:=score;
          exit;
        end
      end;
      DosTimerStop(TimerHandle);
      DosSemSet(SemHandle);
      DosTimerAsync(trunc(15/level*TIMER_MUL),SemHandle,TimerHandle);
    end;
  until false;
end;

procedure done;
var FF:File;
    ii:integer;
begin
  FileMode:=$41;
  assign(FF,'tetris.res');
  rewrite(FF,1);
  close(FF);
  FileMode:=$12;
  reset(FF,1);
  blockwrite(FF,maxrec,2);
  close(FF);
{  for j:=1 to 80 do
  begin
    for i:=0 to 24 do MemW[$B800:i*160] := MakeWord(2,ord(gameover[i+1,81-j]));
    for i:=24 downto 0 do move(mem[$B800:i*160],mem[$B800:i*160+2],160);
  end;}
end;

begin
  clrscr;
  DosCreateSem(1,SemHandle,'\SEM\TETRIS16\TIMER');
  i:=10;
  init;
  run;
  done;
  DosCloseSem(SemHandle);
end.
