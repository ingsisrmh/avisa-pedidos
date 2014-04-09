#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         RMH

 Script Function:
	Avisa si hay pedidos nuevos.

#ce ----------------------------------------------------------------------------

; Script Start

#include <Date.au3>

;Variables Globales
Global $folios[250]
Global $pedidos[250]
Global $NuevosFolios[250]
Global $historialdeFolios[3000]

Local $detener = 10 ;segundos

;MsgBox(64, "Visores: ", Visores())

Guardar(Comparar(Folios(Visores()-1), HistorialFolios()))

While 1
   for $i=0 to (Visores()-1)
	  ;MsgBox(64, "Visores: ", $pedidos[$i])
	  ;MsgBox($MB_SYSTEMMODAL, "", "Diferencia: " & HoraActual() - ModificadoArchivo("\\LINUX\macropro\" & $pedidos[$i]), 1)

	  $diferencia = HoraActual() - ModificadoArchivo("\\LINUX\macropro\" & $pedidos[$i])

	  If $diferencia<3600 Then
		 Guardar(Comparar(Folios(Visores()-1), HistorialFolios()))
	  EndIf
   Next

   ;Esperar 10 segundos
   sleep($detener*1000)
WEnd

;De aquí en adelante comienzan las funciones.
; 1. Abrir la lista de visores.
Func Visores() ;Lee el archivo visores.txt con los visores de los vendedores
   Local $file = FileOpen(@MyDocumentsDir & "\APedidos\visores.txt", 0)
   Local $folio = ""
   Local $a = 0
   Local $b = 0

   If $file = -1 Then
	   MsgBox(64, "Error", "Imposible abrir el archivo " & @MyDocumentsDir & "\APedidos\visores.txt")
	   Exit
   EndIf

   While 1
	  Local $chars = FileRead($file, 1)

	  If @error = -1 Then
		 ExitLoop
	  ElseIf $chars = @LF Then
		 $folio = StringReplace($folio, @CR, "")
		 $pedidos[$a] = $folio
		 $folio = ""
		 $a += 1
	  Else
		 $folio = $folio & $chars
	  EndIf
   WEnd

   FileClose($file)

   Return $a
EndFunc

; 2. Revisar los visores y recolectar todos los números de folio que haya.
Func Folios($CantVisores) ;Lee y guarda los folios los visores de los vendedores
   Local $a = 0

   For $a=0 To $CantVisores Step 1
	  Local $file = FileOpen("\\LINUX\macropro\" & $pedidos[$a], 0)

	  If $file = -1 Then
		  MsgBox(64, "Error", "Imposible recolectar los archivos pedidos de \\LINUX\macropro\... Por favor avisa a Sistemas sobre este error. Es necesrio revisar la conexión al servidor GNU/Linux.", 5)
		  Exit

	  EndIf

	  Local $line = FileReadLine($file, 16)

	  $line = StringRight($line, 49)
	  $line = StringLeft($line, 11)
	  $line = StringReplace($line, " ", "")

	  If StringInStr($line, "P1-") Or StringInStr($line, "PP") Then
		 $folios[$a] = $line
	  EndIf
   Next

   FileClose($file)

   Return $a-1
EndFunc

; 3. Abrir el historial de folio
Func HistorialFolios() ;Lee el archivo folios.txt que tiene El historial de folios
   Local $file = FileOpen(@MyDocumentsDir & "\APedidos\folios.txt", 0)
   Local $folio = ""
   Local $a = 0
   Local $b = 0

   If $file = -1 Then
	   MsgBox(64, "Error", "Imposible abrir el archivo con el historial" & @MyDocumentsDir & "\APedidos\folios.txt")
	   Exit
   EndIf

   While 1
	  Local $chars = FileRead($file, 1)

	  If @error = -1 Then
		 ExitLoop
	  ElseIf $chars = @LF Then
		 $folio = StringReplace($folio, @CR, "")
		 $historialdeFolios[$a] = $folio
		 $folio = ""
		 $a += 1
	  Else
		 $folio = $folio & $chars
	  EndIf
   WEnd

   Return $a-1

   FileClose($file)
EndFunc

; 4. Comparar los folios recolectados con los del historial para ver hay algo nuevo
Func Comparar($CantFolios, $CanthistorialFolios) ;Compara los folios que hay en las variables Globales $folios[250] y Global $historialdeFolios[3000]
   Local $a=0
   Local $f=0
   Local $h=0
   Local $n=0
   Local $esNuevo=0

   For $f=0 To $CantFolios Step 1
	  For $h=0 To $CanthistorialFolios Step 1
		 If $folios[$f] = $historialdeFolios[$h] Then
			$esNuevo += 1
		 EndIf
	  Next

	  If $esNuevo = 0 Then
		 $NuevosFolios[$n] = $folios[$f]
		 $n += 1
	  EndIf

	  $esNuevo=0
   Next

   ; 5. Avisar que se encontraron nuevos folios !!!
   For $a=0 To $n-1 Step 1
	  If StringInStr($NuevosFolios[$a], "P1-") Or StringInStr($NuevosFolios[$a], "PP") Then
		 MsgBox(64, "SE ENCONTRÓ NUEVO PEDIDO", "Folio: " & $NuevosFolios[$a])
	  EndIf
   Next

   Return $n-1
EndFunc

; 6. Guardar los folios nuevos que se encontraron
Func Guardar($n) ;Guarda los folios nuevos que se encontraron
   Local $a=0
   Local $file = FileOpen(@MyDocumentsDir & "\APedidos\folios.txt", 1)

   If $file = -1 Then
	   MsgBox(64, "Error", "Imposible almacenar los nuevos folios en el historial " & @MyDocumentsDir & "\APedidos\folios.txt")
	   Exit
   EndIf

   For $a=0 To $n Step 1
	  FileWriteLine($file, $NuevosFolios[$a] & @CRLF)
   Next

   FileClose($file)
EndFunc

Func HoraActual()
   Local $Fecha
   Local $YYYY
   Local $MM
   Local $DD
   Local $HH
   Local $NN
   Local $SS

   $tCur = _Date_Time_GetLocalTime()
   $CadenaTiempo = _Date_Time_SystemTimeToDateTimeStr($tCur)

   $MM = StringTrimRight($CadenaTiempo, 17)
   $DD = StringTrimRight($CadenaTiempo, 14)
   $DD = StringTrimLeft($DD, 3)
   $YYYY = StringTrimRight($CadenaTiempo, 9)
   $YYYY = StringTrimLeft($YYYY, 6)
   $HH = StringTrimRight($CadenaTiempo, 6)
   $HH = StringTrimLeft($HH, 11)
   $NN = StringTrimRight($CadenaTiempo, 3)
   $NN = StringTrimLeft($NN, 14)
   $SS = StringTrimLeft($CadenaTiempo, 17)

   $FechaActual = $YYYY & $MM & $DD & $HH & $NN & $SS

   Return $FechaActual

EndFunc

Func ModificadoArchivo($Archivo)
   Local $Fecha
   Local $YYYY
   Local $MM
   Local $DD
   Local $HH
   Local $NN
   Local $SS

   $Fecha = FileGetTime($Archivo, $FT_MODIFIED, 1)

   $YYYY = StringTrimRight($Fecha, 10)
   $MM = StringTrimRight($Fecha, 8)
   $MM = StringTrimLeft($MM, 4)
   $DD = StringTrimRight($Fecha, 6)
   $DD = StringTrimLeft($DD, 6)
   $HH = StringTrimRight($Fecha, 4)
   $HH = StringTrimLeft($HH, 8)
   $NN = StringTrimRight($Fecha, 2)
   $NN = StringTrimLeft($NN, 10)
   $SS = StringTrimLeft($Fecha, 12)

   $FechaArchivo = $YYYY & $MM & $DD & $HH & $NN & $SS

   Return $FechaArchivo

EndFunc
