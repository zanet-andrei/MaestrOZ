local
	% See project statement for API details.
	% !!! Please remove CWD identifier when submitting your project !!!
	CWD = 'C:/Users/themy/OneDrive/Desktop/projecttemplate/' % Put here the **absolute** path to the project files
	[Project] = {Link [CWD#'Project2022.ozf']}
	Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Pour vérifier que l'input et le output sont inchangés
	% pre: ExtendedNote = note(name:_ octave:_ sharp:_ duration:_ instrument:_)
	% post: retourne la note non étendue (ex. b#3, ou avec la transformation duration(name:_ _) si ExtendedNote.duration \= 1.0
	fun {ExtendedToNote ExtendedNote}
		case ExtendedNote
		of note(name:X octave:Y sharp:Z duration:S instrument:_) then
			if S == 1.0 then
				if Z  then X#Y
				elseif Y == 4 then X
				else
					{StringToAtom {Concat {AtomToString X} {IntToString Y}}}
				end
			else
				if Z then duration(seconds:S [X#Y])
				elseif Y == 4 then duration(seconds:S [X])
				else
					duration(seconds:S [{StringToAtom {Concat {AtomToString X} {IntToString Y}}}])
				end
			end
		else nil end
	end
	
	% Pour vérifier que l'input et le input sont inchangés
	% pré: TimedList = partition étendue tq dans les spécifications du projet
	% post: partition non étendue
	fun {TimedListToPartition TimedList}
		case TimedList
		of H|T then
			{ExtendedToNote H}|{TimedListToPartition T}
		else nil
		end
	end

	% Convertit une Note en ExtendedNote
	% pré: Note est une note tq a, b#4 ou g7
	% post: Renvoie la note étendue, par ex note(name:a octave:4 sharp:false duration:1.0 instrument:none)
   	fun {NoteToExtended Note}
		case Note
		of Name#Octave then
			note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
		[] Atom then
			case {AtomToString Atom}
			of [_] then
				note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
			[] [N O] then
				note(name:{StringToAtom [N]}
				octave:{StringToInt [O]}
				sharp:false
				duration:1.0
			instrument: none)
			end
		end
	end
 
   % Multiplie la durée d'une ExtendedNote par X  et continue à aplatir la partition
   % pré: Y = ExtendedNote, X = float >= 0.0, PartTail = suite partition 
   % post: Y dont la durée a été multipliée par X
   	fun {Stretch Y X PartTail}
		local Temp in 
			case Y
			of H|T then 
				case H
				of H2|T2 then
					{Stretch H X PartTail}|{Stretch T X PartTail}
				[] note(name:Name octave:Octave sharp:Sharp duration:Duration instrument:Instrument) then
					note(name:Name octave:Octave sharp:Sharp duration:Duration*X instrument:Instrument)|{PartitionToTimedList PartTail}
				else
					Temp = {NoteToExtended H}
					note(name:Temp.name octave:Temp.octave sharp:Temp.sharp	duration:Temp.duration*X instrument:Temp.instrument)|{Stretch T X PartTail}
				end
			[] nil then {PartitionToTimedList PartTail}
			end
		end
   	end

   % Met la durée d'une ExtendedNote à X, et continue à aplatir la partition
   % pré: Y == ExtendedNote, X == float >= 0.0, PartTail = suite partition
   % post: Durée de Y = X, et continue à aplatir la partition
   	fun {Duration Y X PartTail}
		case Y
		of H|T then
			case H
			of H2|T2 then
				{Duration H X PartTail}|{Duration T X PartTail}
			[] note(name:Name octave:Octave sharp:Sharp duration:_ instrument:Instrument) then
			   	note(name:Name octave:Octave sharp:Sharp duration:X instrument:Instrument)|{Duration T X PartTail}
			else
				local Temp in 
			   		Temp = {NoteToExtended H}
			   		note(name:Temp.name octave:Temp.octave sharp:Temp.sharp	duration:X instrument:Temp.instrument)|{Duration T X PartTail}
				end
		   	end
	 	[] nil then {PartitionToTimedList PartTail}
	 	end
   	end
	
   % Étend (si nécessaire) une partition, et la copie N fois
   % pré: L e
   	fun {Copy L L_Bis N PartTail}
    	if N >= 1 then
			case L
			of H|T then
				case H
				of H2|T2 then
					{ChordToExtended H}|{Copy T L_Bis N PartTail}
				[] note(name:_ octave:_ sharp:_ duration:_ instrument:_ ) then
					H|{Copy T L_Bis N PartTail}
				[] _ then
					{NoteToExtended H}|{Copy T L_Bis N PartTail}
				end
			[] nil then {Copy L_Bis L_Bis N-1 PartTail}
			end
		else {PartitionToTimedList PartTail} end
	end

	% Idem que Copy, avec la copie de L L_Bis caché à l'intérieur
   	fun {Drone L N T}
      	{Copy L L N T}
   	end
   
   % Prend un accord en entré, et le transforme en liste de notes étendues
   % pré: Y est une liste de notes ou une liste de vide
   % post: Renvoie la liste de notes étendues, ou la note "silence" si Y est vide.
   	fun {ChordToExtended Y}
    	case Y of H|_ then
			case H
			of nil then [silence(duration:0.0)]
			[] silence(duration:_) then Y
	 		else
				{PartitionToTimedList Y}
			end
    	[] nil then nil
    	end
   	end

   % Concatène deux chaînes de caractères
   % pré: S1 et S2 sont des listes
   % post: renvoie S1|S2|nil
   	fun {Concat S1 S2} 
      	case S1 of H|T then H|{Concat T S2} [] nil then S2 end
   	end

   % Retourne le nombre de demitons dans Note
   % pré: Note est une note de type a, g#5 ou b3
   % post: retourne un entier qui correspond aux demitons de Note
   	fun {GetSemitones Note}
      	case Note
      	of Name#Octave then
	 		if Name == a then 11+((Octave-1)*12)
	 		elseif Name == c then 2+((Octave-1)*12)
	 		elseif Name == d then 4+((Octave-1)*12)
	 		elseif Name == f then 7+((Octave-1)*12)
	 		elseif Name == g then 9+((Octave-1)*12)
	 		else nil end
      	[] Atom then
	 		case {AtomToString Atom}
	 		of [_] then
	    		if Atom == a then 10+(3*12)
	    		elseif Atom == b then 12+(3*12)
	    		elseif Atom == c then 1+(3*12)
	    		elseif Atom == d then 3+(3*12)
	    		elseif Atom == e then 5+(3*12)
	    		elseif Atom == f then 6+(3*12)
	    		elseif Atom == g then 8+(3*12)
	    		else nil end
	 		[] [N O] then
	    		if {StringToAtom [N]} == a then 10+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == b then 12+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == c then 1+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == d then 3+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == e then 5+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == f then 6+(({StringToInt [O]}-1)*12)
	    		elseif {StringToAtom [N]} == g then 8+(({StringToInt [O]}-1)*12)
	    		else nil end
	 		end
      	end
   	end   

   % Retourne sous forme d'atome la note correspondant à l'entrée
   % pré: Semitones est un entier 
   % post: une note de la forme a, d#4 ou b5
   	fun {ReturnNoteAtom Semitones}
      	if Semitones == nil orelse Semitones < 1 then nil
      	else
	 		local Note Octave in
	    		Octave = (Semitones div 12)+1
	    		Note = Semitones mod 12
	    		if Octave == 4 then
	       			if Note == 1 then c
	       			elseif Note == 2 then c#4
	       			elseif Note == 3 then d
	       			elseif Note == 4 then d#4
	       			elseif Note == 5 then e
	       			elseif Note == 6 then f
	       			elseif Note == 7 then f#4
	       			elseif Note == 8 then g
	       			elseif Note == 9 then g#4
	       			elseif Note == 10 then a
	       			elseif Note == 11 then a#4
	       			elseif Note == 0 then b3
	       			end
	    		elseif Octave == 5 andthen Note == 0 then b
	    		else
	       			if Note == 1 then {StringToAtom{Concat "c" {IntToString Octave}}}
	       			elseif Note == 3 then {StringToAtom{Concat "d" {IntToString Octave}}}
	       			elseif Note == 5 then {StringToAtom{Concat "e" {IntToString Octave}}}
	       			elseif Note == 6 then {StringToAtom{Concat "f" {IntToString Octave}}}
	       			elseif Note == 8 then {StringToAtom{Concat "e" {IntToString Octave}}}
	       			elseif Note == 10 then {StringToAtom{Concat "a" {IntToString Octave}}}
	       			elseif Note == 0 then
		  				if Octave == 1 then {StringToAtom{Concat "b" {IntToString Octave}}}
		  				else {StringToAtom{Concat "b" {IntToString Octave-1}}}
		  			end
				
	       			elseif Note == 2 then c#Octave
	       			elseif Note == 4 then d#Octave
	       			elseif Note == 7 then f#Octave
	       			elseif Note == 9 then e#Octave
	       			elseif Note == 11 then a#Octave
	       			end
	    		end
	 		end
      	end
   	end

   % Transpose une liste de notes de Semitones demi-tons
   % pré: NoteList est une liste de notes étendues ou non, Semitones est un entier >= 0, PartTail est la suite de la partition
   % post: La transposition étendue de NoteList, puis continue à aplatir la partition
   	fun {Transpose NoteList Semitones PartTail}
		case NoteList
		of H|T then 
			case H
			of H2|T2 then
				{Transpose H Semitones PartTail}|{Transpose T Semitones PartTail}
			[] note(name:_ octave:_ sharp:_ instrument:_ duration:_) then
				{TransposeSingleExtended H Semitones}|{Transpose T Semitones PartTail}
			else
				if {GetSemitones H} == nil orelse {ReturnNoteAtom ({GetSemitones H} + Semitones)} == nil then nil
				else 
					{TransposeSingle H Semitones}|{Transpose T Semitones PartTail}
				end
			end
		[] nil then {PartitionToTimedList PartTail}
		end
	end

	% Transpose une note étendue de Semitones demi-notes
	% pré: ExtNote est une note étendue, Semitones un entier
	% post: Renvoie ExtNote transposée 
   	fun {TransposeSingleExtended ExtNote Semitones}
		local TransposedNote in 
			case ExtNote
			of note(name:Name octave:Octave sharp:Sharp instrument:I duration:S) then
				if Sharp then
					TransposedNote = {NoteToExtended {ReturnNoteAtom ({GetSemitones Name#Octave}+Semitones)}}
					note(name:TransposedNote.name octave:TransposedNote.octave sharp:TransposedNote.sharp instrument:I duration:S)
				else
					TransposedNote = {NoteToExtended {ReturnNoteAtom ({GetSemitones {StringToAtom {Concat {AtomToString Name} {IntToString Octave}}}}+Semitones)}}
					note(name:TransposedNote.name octave:TransposedNote.octave sharp:TransposedNote.sharp instrument:I duration:S)
				end
			else nil end
		end
	end
	
	% Transpose Note de Semitones demi-tons
	% pré: Note est une note de type a, b#5 ou d4, Semitones est un entier
	% post: Retourne Note étendue et transposée 
	fun {TransposeSingle Note Semitones}
		{NoteToExtended {ReturnNoteAtom ({GetSemitones Note}+Semitones)}}
	end

	% Traite les transformations sur les notes imbriquées
	% pré: Y est un partition item (cf. project_statement.pdf), X le modificateur,
	%      Fun la transformation à appliquer sur la note, PartTail la suite de la partition
	% post: Y traité avec toutes les transformations imbriquées, ensuite continue à aplatir la partition

	fun {CheckTransformations Y X Fun PartTail}
		case Y
		of H|_ then
		   	case H of
		  	stretch(factor:_ _) then
		  		{Fun {PartitionToTimedList Y} X PartTail}
		   	[] duration(seconds:_ _) then
				{Fun {PartitionToTimedList Y} X PartTail}
		   	[] drone(note:_ amount:_) then
				{Fun {PartitionToTimedList Y} X PartTail}
		   	[] transpose(semitones:_ _) then
				{Fun {PartitionToTimedList Y} X PartTail}
			[] _|_ then
				{Fun {ChordToExtended Y} X PartTail}|nil
		   	else {Fun Y X PartTail} end
		end
	 end

	 % Prend en entrée une partition, ensuite renvoie la partition aplatie
	 % pré: Partition est un tuple partition (cf. project_statement.pdf)
	 % post: Renvoie Partition aplatie		
   	fun {PartitionToTimedList Partition}
    	case Partition
		of H|T then
			local Temp in % 'Ruban adhésif' pour résoudre un problème de listes redondantes
						  % Ex: [[[note(...) note(...)] note(...)]] -> [[note(...) note(...)] note(...)]
				case H
					% Stretch
				of stretch(factor:X Y) then 
					Temp = {CheckTransformations Y X Stretch T}
					case Temp
					of H2|T2 then
						if T2 == nil then H2 else Temp end
					end
					% Duration
				[] duration(seconds:X Y) then
					Temp = {CheckTransformations Y X/{CountInList Y 0.0} Duration T}
					case Temp
					of H2|T2 then
						if T2 == nil then H2 else Temp end
					end
					% Drone
				[] drone(note:Y amount:X) then 
					Temp = {CheckTransformations Y X Drone T}
					case Temp
					of H2|T2 then
						if T2 == nil then H2 else Temp end
					end
					% Transpose
				[] transpose(semitones:X Y) then 
					Temp = {CheckTransformations Y X Transpose T}
					case Temp
					of H2|T2 then
						if T2 == nil then H2 else Temp end
					end
					% Chord 
				[] _|_ then
					{ChordToExtended H}|{PartitionToTimedList T}
					% Extended Note
				[] note(name:_ octave:_ sharp:_ duration:_ instrument:_) then
					H|{PartitionToTimedList T}
					% Note
				[] _ then 
					{NoteToExtended H}|{PartitionToTimedList T}
				% End of list
				else nil end
			end
		 % End of partition
    	else nil end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Retourne les demitons dans la note ExtendedNote 
	% pré: ExtendedNote est une note étendue (cf. project_statement.pdf)
	% post: Retourne un entier correspondant au nombre de demitons dans ExtendedNote
	fun {GetSemitonesExtended ExtendedNote}
		case ExtendedNote
		of note(name:Name octave:Octave sharp:Sharp instrument:_ duration:_) then
		   if Name == a andthen Sharp == false then 10.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == a andthen Sharp == true then 11.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == b then 12.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == c andthen Sharp == false then 1.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == c andthen Sharp == true then 2.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == d andthen Sharp == false then 3.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == d andthen Sharp == true then 4.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == e then 5.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == f andthen Sharp == false then 6.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == f andthen Sharp == true then 7.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == g andthen Sharp == false then 8.0+(12.0*({IntToFloat Octave} - 1.0))
		   elseif Name == g andthen Sharp == true then 9.0+(12.0*({IntToFloat Octave} - 1.0))
		   else ~1.0 end
		[] silence(duration:_) then 0.0
		else nil end
	 end

   	% Calcule F
	% pré: Semitones est un float >= 0.0
	% post: retourne la hauteur de la note en Hz
	fun {CalcF Semitones}
		{Pow 2.0 ( (Semitones-46.0) / 12.0 )} * 440.0
	end
	
	% Calcule 1 échantillon à l'instant I
	% pré: F est la hauteur d'une note, I un float >= 0, Rate le taux d'échantillonnage
	% post: retourne l'échantillon à l'instant I
	fun {Sample F I Rate}
		{Sin (2.0 * 3.141 * F * I / Rate)}/2.0
	end
	
	% Calcule Rate * I échantillons de hauteur F 
	% pré: I est un float >= 0, F est un float = la hauteur de une note en Hz, Rate un float = le taux d'échantillonnage,
	% Acc un float = un accumulateur initialisé à 1.0
	% post: Retourne une liste de Rate * I échantillons
	fun {SamplingBis I F Rate Acc}
		if Acc < (Rate * I) then
			{Sample Acc F Rate}|{SamplingBis I F Rate Acc+1.0}
		else nil end
	end

	% Idem SamplingBis avec l'accumulateur initialisé à 1.0 et la fréquence d'échantillonnage par défaut à 44100Hz
	fun {Sampling I F}
		{SamplingBis I F 44100.0 0.0}
	end

	% Crée les échantillons d'une liste de notes
	% pré: L est une liste de notes étendues
	% post: renvoie une liste d'échantillons pour chaque note
	fun {SamplingNotesList L}
		case L
		of H|T then
			case H
			of note(duration:S name:_ octave:_ sharp:_ instrument:_) then
				{Sampling S {CalcF {GetSemitonesExtended H}}}|{SamplingNotesList T}
			end
		[] nil then nil
		end
	end

	% Compte le nombre d'éléments dans une liste
	% pré: L est une liste, Acc un accumulateur
	% post: renvoie Acc, le nombre d'éléments dans la liste
	fun {CountInList L Acc}
		case L
		of H|T then
		   	case H
		   	of H2|T2 then
		  		{CountInList T {CountInList H Acc}}
		   	else
		  		{CountInList T Acc+1.0}
		   	end
		[] nil then Acc end
	end

	% Combine toutes les listes de float imbriquées dans L
	% pré: L est une liste contenant des listes de float imbriquées, Acc un accumulateur initialisé à nil
	% post: une liste contenant la somme de chaque élément aux index respectifs (ex. L[0][0] + L[1][0] + ... L[n][0] -> Retour[0])
	fun {CombineAllBis L Acc}
		case L
		of H|T then
		   {CombineAllBis T {CombineTwo H Acc}}
		   [] nil then Acc
		end
	 end
	
	% idem CombineAllBis avec Acc initialisé à nil
	fun {CombineAll L}
		{CombineAllBis L nil}
	end

	% Crée les échantillons pour un accord
	% pré: L est une liste d'accords étendue, de durées identiques
	% post: renvoie la moyenne cumulée des échantillons
	fun {SamplingChord L}
		{MultList {Flatten {CombineAll {SamplingNotesList L}}} (1.0/{CountInList L 0.0})}
	end
		

	% Coupe les fréquences en dehors de l'intervalle [Low, High]
	% pré: Samples est une liste d'échantillons, Low et High des float compris entre [~1.0, 1.0]
	% post: Retourne Samples avec les fréquences bornées dans l'intervalle [Low, High]
	fun {Clip Samples Low High}
		case Samples
		of H|T then
			if H < Low then
				Low|{Clip T Low High}
			elseif H > High then 
				High|{Clip T Low High}
			else H|{Clip T Low High}
			end
		[] nil then nil
		end
	end

	% Combine deux listes de floats
	% pré: A et B sont deux listes de floats
	% post: combinaison de A et B
	fun {CombineTwo A B}
		case A
		of H|T then
			case B
			of H2|T2 then
				H+H2|{CombineTwo T T2}
			[] nil then
				H|{CombineTwo T nil}
			end
		[] nil then
			case B
			of H2|T2 then
				H2|{CombineTwo nil T2}
			[] nil then nil
			end
		end
	end

	% Multiplie une liste de floats par le facteur Factor
	% pré: List est une liste de floats, Factor est un float
	% post: Retourne les éléments de List multipliés par Factor
	fun {MultList List Factor}
		case List
		of H|T then
			H*Factor|{MultList T Factor}
		[] nil then nil
		end
	end

	% Combine une liste de musiques L
	% pré: L est une liste de Factor#Part
	% post: échantilonne si nécessaire Part, ensuite multiplie par Factor, ensuite aditionne les échantillons. Retourne 1.0#Part
	fun {MergeBis L P2T}
		case L
		of H|T then
			case H
			of Factor#Part then
				case T
				of H2|T2 then
					case H2
					of FactorBis#PartBis then 
						{MergeBis 1.0#{CombineTwo {MultList {MixB P2T Part} Factor} {MultList {MixB P2T PartBis} FactorBis}}|T2 P2T}
					end
				[] nil then H
				end
			end
		[] nil then nil
		end
	end

	% Idem que MergeBis, mais retire le facteur 1.0 devant Part
	fun {Merge L P2T}
		case {MergeBis L P2T}
		of _#Part then
			Part
		[] nil then nil
		end
	end

	% Répète une musique N fois
	% pré: L_Bis est une copie de la liste originelle, L est un accumulateur, N est le nombre de fois à répéter la musique
	% post: L copiée N fois 
	fun {RepeatBis L L_Bis N}
		if N>=1 then
			case L
			of H|T then
				H|{RepeatBis T L_Bis N}
			[] nil then
				{RepeatBis L_Bis L_Bis N-1}
			end
		else nil end
	end

	% Idem que RepeatBis, sert à cacher l'accumulateur
	fun {Repeat L N}
		{RepeatBis L L N}
	end

	% Boucle une musique L pendant S secondes en tronquant les échantillons en trop
	% pré: L_Bis est une copie de la liste originelle, L_Bis un accumulateur, S la quantité en secondes à boucler la musique,
	% Acc un accumulateur initialisé à 0, Rate la fréquence d'échantillonnage
	fun {LoopBis L L_Bis S Acc Rate}
		if (S*Rate) > Acc then
			case L
			of H|T then
				H|{LoopBis T L_Bis S Acc+1.0 Rate}
			[] nil then {LoopBis L_Bis L_Bis S Acc Rate}
			end
		else nil end
	end
	
	% Idem que LoopBis, mais avec les 2 accumulateurs cachés à l'intérieur de la fonction.
	% Rate est initialisé par défaut à 44100.0 (cf. project_statement.pdf)
	fun {Loop L S}
		{LoopBis L L S 0.0 44100.0}
	end

	% Ajoute un echo à la musique L_Bis d'intensité Decay d'une durée S
	% pré: L et Acc sont des accumulateurs, L_Bis est une copie de la liste originelle, S la durée de l'écho,
	% 		P2T la fonction PartitionToTimedList
	% post: La musique L_Bis avec un echo de S secondes d'intensité Decay
	fun {EchoBis L L_Bis S Decay Rate Acc P2T}
		if (S*Rate) > Acc then
			{EchoBis 0.0|L L_Bis S Decay Rate Acc+1.0 P2T}
		else
			{Merge Decay#L|1.0#L_Bis P2T}
		end
	end

	% Idem que Echo mais avec les accumulateurs cachés à l'intérieur de la fonction
	fun {Echo L S Decay P2T}
		{EchoBis L L S Decay 44100.0 1.0 P2T}
	end

	% Récupère la musique dans l'intervalle [Start, End], et complète avec du silence si End excède la durée de la musique
	% pré: L est la musique à couper, Start et End les intervalles de la musique à récupérer,
	% 		Rate le taux d'échantillonnage et Acc un accumulateur
	% post: La musique coupée dans l'intervalle [Start, End]
	fun {CutBis L Start End Rate Acc}
		case L
		of H|T then
			if Acc < (Start*Rate) then
				{CutBis T Start End Rate Acc+1.0}
			elseif Acc >= (Start*Rate) andthen Acc < (End*Rate) then
				H|{CutBis T Start End Rate Acc+1.0}
			else nil end
		[] nil then
			if Acc >= (Start*Rate) andthen Acc < (End*Rate) then
				0.0|{CutBis L Start End Rate Acc+1.0}
			else nil end
		end
	end

	% Idem que CutBis mais avec Acc initialisé, et Rate par défaut à 44100Hz
	fun {Cut L Start End}
		{CutBis L Start End 44100.0 0.0}
	end

	% Retourne la durée en secondes de la chanson
	% pré: L est la chanson, Rate le taux d'échantillonnage, Acc l'accumulateur de secondes
	% post: la durée de L en secondes
	fun {SongLengthBis L Rate Acc}
		case L
		of _|T then
			{SongLengthBis T Rate Acc+1.0}
		else Acc/Rate
		end
	end

	% Idem que SongLength mais avec les accumulateurs cachés, Rate initialisé à 44100Hz
	fun {SongLength L}
		{SongLengthBis L 44100.0 ~1.0}
	end

	% Calcule l'intensité linéaire pendant Seconds secondes à un taux d'échantillonnage Rate à appliquer à la musique
	% pré: Seconds est un float >= 0.0, Rate un taux d'échantillonnage > 0.0
	% post: Une liste contenant l'intensité linéaire à appliquer à la musique
	fun {LinearIntensityBis Seconds Rate Acc}
		if (Seconds*Rate) >= Acc then
			(Acc/(Seconds*Rate))|{LinearIntensityBis Seconds Rate Acc+1.0}
		else nil end
	end

	% Idem que LinearIntensityBis, Rate initialisé par défaut à 44100Hz
	fun {LinearIntensityIn Seconds}
		{LinearIntensityBis Seconds 44100.0 0.0}
	end

	% Idem que LinearIntensityBis, mais pour un fade out, Rate initialisé par défaut à 44100Hz
	fun {LinearIntensityOut Seconds}
		{Reverse {LinearIntensityBis Seconds 44100.0 0.0}}
	end

	% Crée la liste avec les facteurs multiplicatifs devant les échantillons de manière à créer les fade
	% Pré: SectionToFade contient la section de la musique sur laquelle il faut appliquer le fade
	%		Fade est la liste d'intensités à appliquer
	% Post: Liste de Factor#Music, ou Factor et Music sont des float
	fun {ComposeFade SectionToFade Fade}
		case Fade
		of H|T then
			case SectionToFade
			of H2|T2 then
				H*H2|{ComposeFade T T2}
			[] nil then nil
			end
		[] nil then nil
		end
	end

	

	% Crée le fade out pour la musique Music sur les Duration dernières secondes
	% pré: Music est une liste d'échantillons, Duration un float >= 0
	% post: la musique Music avec un fade out linéaire
	fun {ComposeFadeOut Music Duration}
		{ComposeFade {Cut Music {SongLength Music}-Duration {SongLength Music}+(1.0/44100.0)} {LinearIntensityOut Duration}}
	end

	% Crée le fade in pour la musique Music sur les Duration premières secondes
	% pré: Music est une liste d'échantillons, Duration un float >= 0
	% post: la musique Music avec un fade in linéaire
	fun {ComposeFadeIn Music Duration}
		{ComposeFade {Cut Music 0.0 Duration} {LinearIntensityIn Duration}}
	end

	% Applique un FadeIn et un FadeOut sur la musique Music, en laissant la section dans l'intervalle [In, Out] inchangée
	% pré: Music est une liste d'échantillons, In et Out des float >= 0
	% post: la musique Music avec un fade in et fade out linéaire, en laissant la section [In, Out] inchangée
	fun {Fade Music In Out}
		{Flatten {ComposeFadeIn Music In}|{Cut Music In {SongLength Music}-Out}|{ComposeFadeOut Music Out}}
	end

	fun {MixB P2T Music}
		{Flatten {Mix P2T Music}}
	end
	
	% Interpréte la musique Music et retourne une liste d'échantillons à 44100Hz
	% pré: P2T = {PartitionToTimedList}, Music une liste de morceaux (cf. project_statement.pdf)
	% post: Retourne P2T échantillonné à une fréquence de 44100Hz
   	fun {Mix P2T Music}
		case Music
		of H|T then
			case H
			of wave(X) then
				{Project.load X}|{MixB P2T T}
			[] samples(X) then
				X|{MixB P2T T}
			[] partition(X) then
				{MixB P2T {P2T X}}|{MixB P2T T}
			[] merge(X) then
				{Merge X P2T}|{MixB P2T T}
			[] reverse(X) then
				{Reverse {MixB P2T X}}|{MixB P2T T}
			[] repeat(amount:Y X) then
				{Repeat {MixB P2T X} Y}|{MixB P2T T} 
			[] loop(duration:Y X) then
				{Loop {MixB P2T X} Y}|{MixB P2T T}
			[] clip(low:Low high:High X) then
				{Clip {MixB P2T X} Low High}|{MixB P2T T}
			[] echo(delay:S decay:D X) then
				{Echo X S D P2T}|{MixB P2T T}
			[] fade(start:A out:B X) then
				{Fade {MixB P2T X} A B}|{MixB P2T T}
			[] cut(start:A finish:B X) then
				{Cut {MixB P2T X} A B}|{MixB P2T T}
			[] note(name:_ octave:_ sharp:_ duration:S instrument:_ ) then
				{Sampling S {CalcF {GetSemitonesExtended H}}}|{MixB P2T T}
			[] H2|T2 then
				{Flatten {SamplingChord H}}|{MixB P2T T}
			end
		[] nil then nil end
   	end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   	Music = {Project.load CWD#'joy.dj.oz'}
   	Start

	% Uncomment next line to insert your tests.
	\insert 'C:/Users/themy/OneDrive/Desktop/projecttemplate/tests.oz'
	% !!! Remove this before submitting.
in
   	Start = {Time}

	% Uncomment next line to run your tests.
	%{Test MixB PartitionToTimedList}

	% Add variables to this list to avoid "local variable used only once"
	% warnings.
   	{ForAll [NoteToExtended Music] Wait}
	
	% Calls your code, prints the result and outputs the result to `out.wav`.
	% You don't need to modify this.
   	%{Browse {Project.run MixB PartitionToTimedList Music 'out.wav'}}
	%{Browse {MixB PartitionToTimedList [partition([[duration(seconds:1.0 [a]) duration(seconds:1.0 [b]) duration(seconds:1.0 [c])]])]}}
	

	% Shows the total time to run your code.
   	{Browse {IntToFloat {Time}-Start} / 1000.0}
end