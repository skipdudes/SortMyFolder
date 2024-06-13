#!/bin/bash
# Title            : SMF ( SortMyFolder )
# Author           : Marcin Chętnik ( skipdudes1213@gmail.com )
# Created On       : 15.04.2020
# Last Modified By : Marcin Chętnik ( skipdudes1213@gmail.com )
# Last Modified On : 15.04.2020
# Version          : 1.0.0
#
# Description      : Skrypt sortuje podany folder na podstawie rozszerzeń plików, które są w nim zawarte
#                    Tworzy odpowiednie katalogi i przenosi do nich pliki o odpowiednich rozszerzeniach
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

# KOMENTARZ OD AUTORA
# Jeżeli po wywoałniu programu zenity występuje instrukcja switch case, to
# 0) oznacza przypadek, w którym użytkownik wcisnął Tak, OK
# 1) oznacza przypadek, w którym użytkownik wcisnął Nie, Anuluj
# -1) oznacza przypadek, w którym nastąpił błąd programu zenity
# Piszę to tutaj, aby nie powtarzać tego kilka razy w dalszej części kodu

CONFIG_NAZWA=smfconfig.cfg # nazwa pliku, w którym przechowywana jest konfiguracja programu
VERSION="1.0.0" # wersja programu
AUTHOR="Marcin Chętnik" # autor programu

sortFolder() # Funkcja sortująca wybrany folder
{
	KOPIA_LOKALIZACJI=$LOKALIZACJA # Tworzy kopię nazwy lokalizacji w celu potencjalnej próby przywrócenia jej w przyszłości
	LOKALIZACJA=`echo $LOKALIZACJA | sed 's/ /_/g'` # Zastępuje wszystkie spacje w nazwie lokalizacji podłogami
	
	if [[ $KOPIA_LOKALIZACJI != $LOKALIZACJA ]] # Sprawdza czy nazwa lokalizacji składa się z więcej niż jednego słowa
	then
		`mv "$KOPIA_LOKALIZACJI" "$LOKALIZACJA"` # Jeśli tak, to zmienia nazwę lokalizacji na tę z podłogami
	fi

	while IFS= read -r LINIA || [[ -n "$LINIA" ]]; do # Wczytuje linie z pliku konfiguracyjnego
		NAZWA_FOLDERU=`echo $LINIA | cut -d " " -f 1` # Pobiera nazwę katalogu
		for ROZSZERZENIE in $LINIA; do
			if [[ $ROZSZERZENIE != $NAZWA_FOLDERU ]] # Dla każdego rozszerzenia występującego w linii po nazwie katalogu
			then
				SZUKAJ=`find "$LOKALIZACJA" -type f -maxdepth 1 -name *.$ROZSZERZENIE` # Wyszukuje pliki o aktualnie odczytanym rozszerzeniu w podanej lokalizacji

				if [[ $SZUKAJ != "" ]] # Jeżeli znaleziono pasujące pliki
				then
					SPRAWDZ=`find "$LOKALIZACJA" -type d -name $NAZWA_FOLDERU` # Sprawdza czy istnieje już folder o nazwie $NAZWA_FOLDERU
					if [[ $SPRAWDZ == "" ]]
					then
						`mkdir "$LOKALIZACJA"/$NAZWA_FOLDERU` # Jeśli nie, to go tworzy
					fi
					`mv $SZUKAJ "$LOKALIZACJA"/$NAZWA_FOLDERU` # Przenosi znalezione pliki do odpowiedniego folderu
				fi
			fi
		done
		NAZWA_BEZ_UNDERSCORE=`echo $NAZWA_FOLDERU | sed 's/_/ /g'` # Do zmiennej NAZWA_BEZ_UNDERSCORE zapisuje nazwę katalogu z podłogami zamienionymi na spacje
		if [[ $NAZWA_FOLDERU != $NAZWA_BEZ_UNDERSCORE ]] # Sprawdza czy nazwa katalogu składa się z więcej niż jednego słowa
		then
			SPRAWDZ=`find "$LOKALIZACJA" -type d -name $NAZWA_FOLDERU` # Sprawdza czy taki folder w ogóle istnieje (czy były do niego przenoszone pliki)
			if [[ $SPRAWDZ != "" ]]
			then
				`mv ""$LOKALIZACJA"/$NAZWA_FOLDERU/" ""$LOKALIZACJA"/$NAZWA_BEZ_UNDERSCORE/"` # Jeśli tak, to usuwa mu podłogi z nazwy i zastępuje je spacjami
			fi
		fi
	done < $CONFIG_NAZWA # Wczytuj z tego pliku konfiguracyjnego

	if [[ $KOPIA_LOKALIZACJI != $LOKALIZACJA ]] # Ponownie sprawdza czy nazwa lokalizacji składa się z więcej niż jednego słowa
	then
		`mv "$LOKALIZACJA" "$KOPIA_LOKALIZACJI"` # Jeśli tak, to usuwa z nazwy lokalizacji podłogi i zastępuje je spacjami
	fi
}

changeConfig() # Umożliwia zmianę parametrów sortowania folderu
{
	# Informuje użytkownika, że w następnym oknie będzie mógł on zmienić konfigurację
	`zenity --warning --title="SMF - Zmień ustawienia sortowania" --text="Zamierzasz zmienić konfigurację programu.\n\nProszę wprowadzić własne parametry sortowania." --height=100 --width=300`
	touch "new$CONFIG_NAZWA" # Tworzy nowy plik, w którym przechowa nową, wprowadzoną przez użytkownika konfigurację
	`zenity --text-info --height=300 --width=300 --title="SMF - Zmień ustawienia sortowania" --filename=$CONFIG_NAZWA --editable > "new$CONFIG_NAZWA"` # Tworzy okno do edycji parametrów sortowania
	case $? in
		0)
			# zapisuje wprowadzone zmiany do nowoutworzonego pliku tymczasowego
			`rm $CONFIG_NAZWA` # usuwa stary plik z konfiguracjami
			`mv "new$CONFIG_NAZWA" $CONFIG_NAZWA` # zmienia nazwę nowego pliku z konfiguracjami, przywraca oryginalną
			`zenity --info --title="SMF - Zmień ustawienia sortowania" --text="Pomyślnie zmieniono konfigurację sortowania." --height=100 --width=300`;;
		1)
			`rm "new$CONFIG_NAZWA"` # usuwa nowoutworzony plik, nie jest on już potrzebny
			`zenity --warning --title="SMF - Zmień ustawienia sortowania" --text="Anulowano zmianę konfiguracji." --height=100 --width=200`;;
	   -1)
			`rm "new$CONFIG_NAZWA"`
			`zenity --error --title="SMF - Zmień ustawienia sortowania" --text="Wystąpił nieoczekiwany błąd.\n\nKończę pracę programu." --height=100 --width=200`
			exit;; # Wychodzi z programu z programu
	esac
}

createDefaultConfig() # Tworzy domyślny plik konfiguracyjny
{
	echo "Archiwa cab rar tar zip tgz
Dokumenty pdf doc docx
Filmy avi mov mpe mpg mpeg
Ikony ico
Muzyka mp3 wav wave ogg
Obrazy bmp gif img jpg jpeg png tif tiff
Obrazy_dysków iso
Pliki_tekstowe rtf txt
Pliki_wykonywalne exe
Pliki_źródłowe cpp c" > $CONFIG_NAZWA # Zapisuje domyślną konfigurację do pliku konfiguracyjnego
}

checkConfig() # Sprawdcza czy istnieje plik konfiguracyjny, jeśli nie - wywołuje powyższą funkcję
{
	SPRAWDZ_CONFIG=`find -maxdepth 1 -type f -name $CONFIG_NAZWA` # Sprawdza czy istnieje plik konfiguracyjny
	if [[ $SPRAWDZ_CONFIG == "" ]]
	then
		createDefaultConfig # Jeśli nie, to go tworzy
	fi
}

printHelp() # Wypisuje pomoc, czyli listę opcji wywołania programu
{
	echo "Opcje :"
	echo "-f \"LOKALIZACJA\" - sortuj folder LOKALIZACJA w trybie szybkim (bez okien)"
	echo "-h               - pomoc "
	echo "-v               - wersja "
}

printAbout() # Wypisuje informajce o programie, wersji i autorze
{
	echo "Skrypt organizujący folder w katalogi o danych typach plików."
	echo "Autor: $AUTHOR"
	echo "Werjsa: $VERSION"
}

checkFolder() # Sprawdza czy podany folder istnieje
{
	`touch "$LOKALIZACJA"/checking_if_the_given_folder_exists 2>/dev/null` # Tworzy tymczasowy plik w celu sprawdzenia istnienia folderu

	case $? in
		0)
			`rm "$LOKALIZACJA"/checking_if_the_given_folder_exists`;; # Folder istnieje, usuwa tymczasowy plik
		1)
			echo "Błąd: Nie ma takiego katalogu!"
			exit;; # Folder nie istnieje, wypisuje komunikat i wychodzi z programu
	esac
}

# ************************ MAIN ************************

checkConfig
# Nawet jeśli sortowanie się nie wykona (nie zostanie podana lokalizacja lub program zostanie uruchomiony w trybie informacyjnym [pomoc lub werjsa])
# to program sprawdzi istnienie pliku z konfiguracją i jesli taki nie istnieje, stworzy go

LOKALIZACJA="" # Zmienna przechowująca folder do posortowania

while getopts :f:hv WYBOR 2>/dev/null; do # Wczytanie opcji programu
	case $WYBOR in
		f) # Fastmode
			LOKALIZACJA=$OPTARG # Ustawia dodatkowy argument jako folder do posortowania
			checkFolder # Sprawdza czy folder istnieje

			sortFolder # Sortuje podany folder
			
			echo "Pomyślnie posortowano folder $LOKALIZACJA"
			exit;; # Wychodzi z programu
		h) # Pomoc
			printHelp
			exit;;
		v) # Wersja
			printAbout
			exit;;
		:) # Nieprawidłowo użyty fastmode
			echo "Błąd: Nie podano lokalizacji."
			echo "Poprawne użycie: ./SMF.sh -f \"LOKALIZACJA\""
			exit;;
		?) # Nieprawidłowa opcja
			echo "Nieprawidłowa opcja, wpisz -h w celu uzyskania pomocy."
			exit;;
	esac	
done

# Program uruchomiony bez opcji, zatem uruchamiam program w normalnym trybie, ze wszystkimi oknami
# i możliwością zmiany pliku konfiguracyjnego

# Wyświetla ekran powitalny
`zenity --info --title="SMF - Okno powitalne" --text="Witaj w programie SortMyFolder!\n\nWybierz proszę folder, który chcesz posortować." --height=100 --width=300`
# Pozwala wybrać folder do posortowania
LOKALIZACJA=`zenity --file-selection --title="SMF - Wybierz folder do posortowania" --directory`

case $? in
	0) # Wybrano folder do posortowania
		POTWIERDZONO_CONFIG=0 # Przechowuje informację, czy użytkownik potwiedził konfigurację

		while [[ $POTWIERDZONO_CONFIG == 0 ]] # Dopóki użytkownik nie potwierdzi konfiguracji
		do

			`cat $CONFIG_NAZWA | zenity --text-info --height=300 --width=300 --title="SMF - Czy konfiguracja jest poprawna?"` # Wyświetla obecną konfigurację i pyta czy ją zmienić
			
			case $? in
				0) POTWIERDZONO_CONFIG=1;; # Potwierdza wybór konfiguracji przez użytkownika
				1) changeConfig;; # Użytkownik nie potwierdził konfiguracji - zmienia parametry sortowania
			   -1) `zenity --error --title="SMF - Podsumowanie" --text="Wystąpił nieoczekiwany błąd.\n\nKończę pracę programu." --height=100 --width=200`
				   exit;;
			esac

		done

		# Informuje o próbie rozpoczęcia sortowania
		`zenity --question --title="SMF - Rozpoczęcie sortowania" --text "Plik konfiguracyjny potwierdzony.\n\nCzy mam rozpocząć sortowanie?" --height=100 --width=250`
		
		case $? in
			0) # Zaakceptowano próbę rozpoczęcia sortowania
				( for A in  `seq 1 10 100`; do echo $A; sleep 0.05; done ) | `zenity --progress --height=100 --width=300 --text="Sortuję $LOKALIZACJA" --title "SMF - Sortuję folder"`
				case $? in
					0) # Użytkownik poczekał aż skończy się animacja
						sortFolder # Sortuje folder
						`zenity --info --title="SMF - Podsumowanie" --text="Pomyślnie posortowano katalog!\n\nKończę pracę programu." --height=100 --width=200`;; # Wyświetla podsumowanie

					1) `zenity --warning --title="SMF - Podsumowanie" --text="Anulowano sortowanie.\n\nKończę pracę programu." --height=100 --width=200`;; # Przerwano sortowanie

				   -1) `zenity --error --title="SMF - Podsumowanie" --text="Wystąpił nieoczekiwany błąd.\n\nKończę pracę programu." --height=100 --width=200`;;
				esac;;

			1) `zenity --warning --title="SMF - Podsumowanie" --text="Anulowano sortowanie.\n\nKończę pracę programu." --height=100 --width=200`;;

		   -1) `zenity --error --title="SMF - Podsumowanie" --text="Wystąpił nieoczekiwany błąd.\n\nKończę pracę programu." --height=100 --width=200`;;
		esac;;

	1) `zenity --warning --title="SMF - Podsumowanie" --text="Nie wybrano żadnej lokalizacji.\n\nKończę pracę programu." --height=100 --width=200`;;

   -1) `zenity --error --title="SMF - Podsumowanie" --text="Wystąpił nieoczekiwany błąd.\n\nKończę pracę programu." --height=100 --width=200`;;
esac

# Koniec skryptu
