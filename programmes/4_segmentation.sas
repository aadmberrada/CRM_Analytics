/********************************* Constuction de la segmentation **************************/
/*application des seuils RFM*/
Data application_seuil;
	set indicateur_RFM;

	if 6<recence then
		seg_recence="R1";
	else if 2<recence<=6 then
		seg_recence="R2";
	else if recence<=2 then
		seg_recence="R3";
	else
		seg_recence="?";

	if frequence=1 then
		seg_frequence="F1";
	else if 2<=frequence<=3 then
		seg_frequence="F2";
	else if 3<frequence then
		seg_frequence="F3";
	else
		seg_frequence="?";

	if montant<50 then
		seg_montant="M1";
	else if 50<=montant<100 then
		seg_montant="M2";
	else if 100<=montant then
		seg_montant="M3";
	else
		seg_montant="?";
run;

proc export data=work.application_seuil 
		outfile="Projet RFM\resultats\tables\7_application_seuil.csv" dbms=csv;
	delimiter=";";
run;

/*Vérifier la distribution de ces variables*/
proc freq data=application_seuil;
	table seg_recence seg_frequence seg_montant;
run;

/*résultat parfait*/
/*Croissement de la récence et de la fréquence et construction du groupe RF*/
/*Analyser la distribution du croissement des segments et de récence et de fréquence*/
proc freq data=application_seuil;
	table seg_recence*seg_frequence/out=croisement_recence_frequence;
run;

/*Création de la table application_seuil_RF avec une variable supplémentaire liée à l'application des seuils issus des regroupement RF*/
Data application_seuil_RF;
	set application_seuil;

	if (seg_recence="R1" and seg_frequence="F1") or (seg_recence="R1" and 
		seg_frequence="F2") then
			seg_RF="RF1";
	else if (seg_recence="R1" and seg_frequence="F3") or (seg_recence="R2" and 
		seg_frequence="F1") or (seg_recence="R2" and seg_frequence="F2") 
		or (seg_recence="R3" and seg_frequence="F1") then
			seg_RF="RF2";
	else if (seg_recence="R2" and seg_frequence="F3") or (seg_recence="R3" and 
		seg_frequence="F2") or (seg_recence="R3" and seg_frequence="F3") then
			seg_RF="RF3";
	else
		seg_RF="?";
run;

proc export data=work.application_seuil_RF 
		outfile="Projet RFM\resultats\tables\8_application_seuil_RF.csv" dbms=csv;
	delimiter=";";
run;

/*Analyser la distribution de la variable seg_RF*/
proc freq data=application_seuil_RF;
	table seg_RF;
run;

/*Analyser la distribution du croissement des segments RF et montant */
Proc freq data=application_seuil_RF;
	table seg_RF* seg_montant/out=croisement_RF_montant;
run;

/*On définit les 9 groupes RFM */
Data segment_RFM;
	set application_seuil_RF;

	if seg_RF="RF1" and seg_montant="M1" then
		seg_RFM="RFM1";
	else if seg_RF="RF1" and seg_montant="M2" then
		seg_RFM="RFM2";
	else if seg_RF="RF1" and seg_montant="M3" then
		seg_RFM="RFM3";
	else if seg_RF="RF2" and seg_montant="M1" then
		seg_RFM="RFM4";
	else if seg_RF="RF2" and seg_montant="M2" then
		seg_RFM="RFM5";
	else if seg_RF="RF2" and seg_montant="M3" then
		seg_RFM="RFM6";
	else if seg_RF="RF3" and seg_montant="M1" then
		seg_RFM="RFM7";
	else if seg_RF="RF3" and seg_montant="M2" then
		seg_RFM="RFM8";
	else if seg_RF="RF3" and seg_montant="M3" then
		seg_RFM="RFM9";
	else
		seg_RFM="?";
run;

proc export data=work.segment_RFM 
		outfile="Projet RFM\resultats\tables\9_segment_RFM.csv" dbms=csv;
	delimiter=";";
run;

/*Analyse de la distribution par segment*/
Proc freq data=segment_RFM;
	table seg_RFM;
run;