// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get aLongWhile => 'Un bel po\' di tempo';

  @override
  String get about => 'Informazioni';

  @override
  String get accentColor => 'Colore Accent';

  @override
  String get add => 'Aggiungi';

  @override
  String get addBookmark => 'Aggiungi Segnalibro';

  @override
  String get addNewGroup => 'Aggiungi Nuovo Gruppo';

  @override
  String get addPiece => 'Aggiungi Pezzo';

  @override
  String get addPracticeSession => 'Aggiungi Sessione di Pratica';

  @override
  String get addStage => 'Aggiungi Fase';

  @override
  String get addTag => 'Aggiungi tag';

  @override
  String get addTagGroup => 'Aggiungi Gruppo di Tag';

  @override
  String get addToRepertoire => 'Aggiungi al Repertorio';

  @override
  String get adithyaJayan => 'Adithya Jayan';

  @override
  String get adithyajayanInMyrepertoirapp => 'adithyajayan.in/MyRepertoirApp/';

  @override
  String get advancedSettings => 'Impostazioni Avanzate';

  @override
  String get all => 'Tutti';

  @override
  String get allPieces => 'Tutti i Pezzi';

  @override
  String get allowAddingNotesToSessions =>
      'Consenti l\'aggiunta di note alle sessioni';

  @override
  String get alphabetical => 'Alfabetico';

  @override
  String get anyTime => 'Qualsiasi Momento';

  @override
  String get apache20 => 'Apache 2.0';

  @override
  String get appDocuments => 'Documenti App';

  @override
  String get appInformation => 'Informazioni App';

  @override
  String get appLanguage => 'Lingua App';

  @override
  String get languageName => 'Italiano';

  @override
  String get appTheme => 'Tema App';

  @override
  String get appTitle => 'Repertoire';

  @override
  String get appearanceAnswer =>
      'Vai a Impostazioni > Personalizzazione per cambiare temi, colori accent e opzioni di layout.';

  @override
  String get appearanceQuestion => 'Come cambio l\'aspetto dell\'app?';

  @override
  String get apply => 'Applica';

  @override
  String get applyAndClose => 'Applica e Chiudi';

  @override
  String get applyFilters => 'Applica Filtri';

  @override
  String get areYouSureYouWantToDeleteTheDebugLogFile =>
      'Sei sicuro di voler eliminare il file di log di debug?';

  @override
  String get areYouSureYouWantToDeleteThisMusicPiece =>
      'Sei sicuro di voler eliminare questo pezzo musicale?';

  @override
  String get areYouSureYouWantToDeleteThisPracticeSessionThisAction =>
      'Sei sicuro di voler eliminare questa sessione di pratica? Questa azione non può essere annullata.';

  @override
  String get artistComposer => 'Artista / Compositore';

  @override
  String get associatedTags => 'Tag Associati:';

  @override
  String get audio => 'Audio';

  @override
  String get audioFile => 'File Audio';

  @override
  String get audioFileDoesNotExist => 'Il file audio non esiste';

  @override
  String get audioMidi => 'Audio/MIDI';

  @override
  String get audioNotLoadedYetPleaseWait =>
      'Audio non ancora caricato. Attendi.';

  @override
  String get autoBackupCompletedSuccessfully =>
      'Backup automatico completato con successo!';

  @override
  String autoBackupFailed(String error) {
    return 'Backup automatico non riuscito: $error';
  }

  @override
  String get autoBackupFailedStoragePathNotConfigured =>
      'Backup automatico non riuscito: Percorso di archiviazione non configurato.';

  @override
  String get autoBackupStartingInAFewSeconds =>
      'Avvio backup automatico tra pochi secondi...';

  @override
  String get autoScrollEnabled => 'Scorrimento Automatico Abilitato';

  @override
  String get automaticBackupFoundMessage =>
      'È stato trovato un backup automatico nella cartella di archiviazione selezionata. Desideri ripristinarlo?\n\nNota: Questo sostituirà tutti i dati di template creati durante l\'installazione.';

  @override
  String get automaticBackups => 'Backup Automatici';

  @override
  String get automaticallyCreateBackupsAtRegularIntervals =>
      'Crea automaticamente backup a intervalli regolari';

  @override
  String get averageTime => 'Tempo Medio';

  @override
  String get back1sHoldForFrameSkip =>
      'Indietro 1s (Tieni premuto per saltare frame)';

  @override
  String get back5s => 'Indietro 5s';

  @override
  String get backingUpData => 'Backup dei dati in corso...';

  @override
  String get backupAndRestore => 'Backup e Ripristino';

  @override
  String get backupAnswer =>
      'Sì, visita Impostazioni > Backup e Ripristino per eseguire backup locali manuali o automatici.';

  @override
  String get backupCancelled => 'Backup annullato.';

  @override
  String backupFailed(String error) {
    return 'Backup non riuscito: $error';
  }

  @override
  String get backupFailedStoragePathNotConfigured =>
      'Backup non riuscito: Percorso di archiviazione non configurato.';

  @override
  String get backupFrequencyDays => 'Frequenza Backup (giorni)';

  @override
  String get backupQuestion => 'C\'è un modo per fare il backup dei miei dati?';

  @override
  String get backupRestoredSuccessfully => 'Backup ripristinato con successo.';

  @override
  String get basicDetails => 'Dettagli di Base';

  @override
  String get beenAWhile => 'È passato un po\'';

  @override
  String get beenTooLong => 'È passato troppo tempo';

  @override
  String get blank => 'Vuoto';

  @override
  String bookmarkDefaultName(int number) {
    return 'Segnalibro $number';
  }

  @override
  String bookmarkDeleted(String bookmarkName) {
    return '$bookmarkName eliminato';
  }

  @override
  String bookmarkDismissed(String bookmarkName) {
    return '$bookmarkName ignorato';
  }

  @override
  String get bookmarks => 'Segnalibri';

  @override
  String get browseAndManageInternalAppFiles =>
      'Sfoglia e gestisci i file app interni';

  @override
  String get browserDownloads => 'Download del Browser';

  @override
  String get bulkEditTagGroupsAndColors =>
      'Modifica in massa gruppi di tag e colori';

  @override
  String get cancel => 'Annulla';

  @override
  String get captureTechnicalLogsForTroubleshooting =>
      'Cattura log tecnici per la risoluzione dei problemi';

  @override
  String get changeColor => 'Cambia Colore';

  @override
  String get changeImage => 'Cambia Immagine';

  @override
  String get changeStorageFolder => 'Cambia Cartella di Archiviazione';

  @override
  String channelDefaultName(int number) {
    return 'Canale $number';
  }

  @override
  String get checkForUpdatesNow => 'Controlla Aggiornamenti Ora';

  @override
  String get checkGithubForAppUpdates =>
      'Controlla GitHub per aggiornamenti app';

  @override
  String get chooseGroupColor => 'Scegli Colore Gruppo';

  @override
  String get chooseYourAccentColor => 'Scegli il tuo colore accent:';

  @override
  String get classification => 'Classificazione';

  @override
  String get cleanup => 'Pulizia';

  @override
  String cleanupPartialMessage(int deletedCount, int errorCount) {
    String _temp0 = intl.Intl.pluralLogic(
      deletedCount,
      locale: localeName,
      other: '$deletedCount file',
      one: '1 file',
    );
    String _temp1 = intl.Intl.pluralLogic(
      errorCount,
      locale: localeName,
      other: '$errorCount errori',
      one: '1 errore',
    );
    return 'Eliminato $_temp0 ma incontrato $_temp1.';
  }

  @override
  String cleanupSuccessMessage(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file non utilizzati',
      one: '1 file non utilizzato',
    );
    return 'Eliminati con successo $_temp0 ($size liberati).';
  }

  @override
  String get cleanupSummary => 'Riepilogo Pulizia';

  @override
  String get clearAll => 'Cancella Tutto';

  @override
  String get clearFilter => 'Cancella Filtro';

  @override
  String get close => 'Chiudi';

  @override
  String get color => 'Colore';

  @override
  String get columns => 'Colonne';

  @override
  String get count => 'Conteggio';

  @override
  String get configureAutoScroll => 'Configura Scorrimento Automatico';

  @override
  String get configureLearningProgress =>
      'Configura Progresso di Apprendimento';

  @override
  String get configureMidiTracks => 'Configura Tracce MIDI';

  @override
  String get configurePdfViewer => 'Configura Visualizzatore PDF';

  @override
  String get configureProgressBar => 'Configura Barra di Progresso';

  @override
  String get confirmRestore => 'Conferma Ripristino';

  @override
  String get confirmRestoreMessage =>
      'Sei sicuro di voler ripristinare da questo backup? Questo sostituirà tutti i tuoi dati attuali.';

  @override
  String get contentAndDisplay => 'Contenuto e Display';

  @override
  String contributionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contributi',
      one: '1 contributo',
    );
    return '$_temp0';
  }

  @override
  String get contributors => 'Contributori';

  @override
  String get coral => 'Corallo';

  @override
  String get couldNotOpenLogFile => 'Impossibile aprire il file di log';

  @override
  String countProgress(int current, int max) {
    return 'Conteggio: $current / $max';
  }

  @override
  String get create => 'Crea';

  @override
  String get createABackupOfAllYourData =>
      'Crea un backup di tutti i tuoi dati';

  @override
  String get createLocalBackup => 'Crea Backup Locale';

  @override
  String get createNewPiece => 'Crea Nuovo Pezzo';

  @override
  String createdAt(String date) {
    return 'Creato: $date';
  }

  @override
  String get creatingAutoBackup => 'Creazione auto-backup in corso...';

  @override
  String get credits => 'Crediti';

  @override
  String currentStage(String stage) {
    return 'Fase Attuale: $stage';
  }

  @override
  String get customCategoriesAnswer =>
      'Sì, vai a Impostazioni > Gruppi per creare e gestire gruppi personalizzati per i tuoi pezzi.';

  @override
  String get customCategoriesQuestion =>
      'Posso organizzare la mia musica in categorie personalizzate?';

  @override
  String get customColor => 'Colore Personalizzato';

  @override
  String get dark => 'Scuro';

  @override
  String get dataBackedUpSuccessfully =>
      'Backup dei dati completato con successo!';

  @override
  String get dataManagement => 'Gestione Dati';

  @override
  String get dataRestoredSuccessfully => 'Dati ripristinati con successo!';

  @override
  String get dateAndTime => 'Data e Ora';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get defaultColor => 'Predefinito';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteBookmark => 'Elimina segnalibro';

  @override
  String get deleteConfirmation => 'Conferma Eliminazione';

  @override
  String deleteFileItemsConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return 'Sei sicuro di voler eliminare $_temp0? Questo potrebbe rompere i link nei tuoi pezzi musicali.';
  }

  @override
  String get deleteFiles => 'Elimina File';

  @override
  String get deleteGroup => 'Elimina Gruppo';

  @override
  String deleteGroupConfirmation(String groupName) {
    return 'Sei sicuro di voler eliminare il gruppo \"$groupName\"?';
  }

  @override
  String deleteGroupWithItemsConfirmation(String groupName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return 'Sei sicuro di voler eliminare il gruppo \"$groupName\"?\n\nQuesto gruppo contiene $_temp0. I pezzi musicali associati SOLO a questo gruppo verranno spostati al gruppo \"Non Raggruppato\".';
  }

  @override
  String get deleteItem => 'Elimina Elemento';

  @override
  String get deleteItems => 'Elimina Elementi?';

  @override
  String get deleteLogFile => 'Elimina File di Log?';

  @override
  String get deleteLogs => 'Elimina Log';

  @override
  String get deleteLogs2 => 'Elimina Log?';

  @override
  String get deleteMediaItem => 'Elimina elemento multimediale';

  @override
  String get deleteMusicPiece => 'Elimina Pezzo Musicale';

  @override
  String deleteNamedItem(String name) {
    return 'Elimina \"$name\"';
  }

  @override
  String get deletePracticeSession => 'Elimina Sessione di Pratica';

  @override
  String deleteSelectedItemsConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi selezionati',
      one: '1 elemento selezionato',
    );
    return 'Sei sicuro di voler eliminare $_temp0?';
  }

  @override
  String get deleteTag => 'Elimina Tag';

  @override
  String get deleteTagGroup => 'Elimina Gruppo di Tag';

  @override
  String get deleteTagGroup2 => 'Elimina gruppo di tag';

  @override
  String deleteTagGroupConfirmation(String groupName) {
    return 'Sei sicuro di voler eliminare il gruppo di tag \"$groupName\" e rimuoverlo da tutti i pezzi?';
  }

  @override
  String get deny => 'Nega';

  @override
  String get details => 'Dettagli';

  @override
  String get developedBy => 'Sviluppato da';

  @override
  String get developerTools => 'Strumenti Sviluppatore';

  @override
  String get discard => 'Scarta';

  @override
  String get dismiss => 'Ignora';

  @override
  String get displayOptions => 'Opzioni Display';

  @override
  String get doNotShowGroupsWithNoMatchingPieces =>
      'Non mostrare gruppi senza pezzi corrispondenti';

  @override
  String get documentsRepertoireApp => 'Documenti/RepertoireApp';

  @override
  String get doubleTapNameToEdit => '(Doppio tap sul nome per modificare)';

  @override
  String get duplicate => 'Duplica';

  @override
  String durationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ore',
      one: '1 ora',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '1 minuto',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get durationMinutesLabel => 'Durata (minuti)';

  @override
  String get eG30 => 'es. 30';

  @override
  String get eGWorkedOnDynamicsFocusedOnDifficultPassages =>
      'es. Lavoro sulle dinamiche, focus sui passaggi difficili';

  @override
  String get edit => 'Modifica';

  @override
  String get editGroupName => 'Modifica Nome Gruppo';

  @override
  String get editPiece => 'Modifica Pezzo';

  @override
  String get editPracticeSession => 'Modifica Sessione di Pratica';

  @override
  String get empty => 'Vuoto';

  @override
  String get enableAutomaticBackups => 'Abilita Backup Automatici';

  @override
  String get enableDebugLogs => 'Abilita Log di Debug';

  @override
  String get enablePracticeTracking => 'Abilita Tracciamento Pratica';

  @override
  String get enterFilterName => 'Inserisci nome filtro';

  @override
  String get enterTitleForTheNewPiece => 'Inserisci titolo per il nuovo pezzo';

  @override
  String errorAddingGroup(String error) {
    return 'Errore nell\'aggiunta del gruppo: $error';
  }

  @override
  String errorAddingMedia(String error) {
    return 'Errore nell\'aggiunta di media: $error';
  }

  @override
  String mediaAddedToPiece(String title) {
    return 'Media aggiunto a \"$title\"';
  }

  @override
  String newPieceCreatedWithSharedMedia(String title) {
    return 'Nuovo pezzo \"$title\" creato con media condiviso';
  }

  @override
  String get repertoireAppDebugLog => 'Log di debug dell\'app Repertoire';

  @override
  String get sharedMedia => 'Media Condiviso';

  @override
  String errorChangingStorageFolder(String error) {
    return 'Errore nel cambio della cartella di archiviazione: $error';
  }

  @override
  String errorDeletingGroup(String error) {
    return 'Errore nell\'eliminazione del gruppo: $error';
  }

  @override
  String errorDeletingLogFile(String error) {
    return 'Errore nell\'eliminazione del file di log: $error';
  }

  @override
  String errorDeletingLogs(String error) {
    return 'Errore nell\'eliminazione dei log: $error';
  }

  @override
  String errorDeletingMusicPieces(String error) {
    return 'Errore nell\'eliminazione dei pezzi musicali: $error';
  }

  @override
  String errorDeletingPracticeSession(String error) {
    return 'Errore nell\'eliminazione della sessione di pratica: $error';
  }

  @override
  String errorDuplicatingMusicPiece(String error) {
    return 'Errore nella duplicazione del pezzo musicale: $error';
  }

  @override
  String errorExportingBackup(String error) {
    return 'Errore nell\'esportazione del backup: $error';
  }

  @override
  String errorFetchingThumbnail(String error) {
    return 'Errore nel recupero della miniatura: $error';
  }

  @override
  String errorGeneratingThumbnail(String error) {
    return 'Errore nella generazione della miniatura: $error';
  }

  @override
  String errorInitializingAudio(String error) {
    return 'Errore nell\'inizializzazione dell\'audio: $error';
  }

  @override
  String errorInitializingPlayer(String error) {
    return 'Errore nell\'inizializzazione del lettore: $error';
  }

  @override
  String get errorLoading => 'Errore di caricamento';

  @override
  String errorLoadingGroups(String error) {
    return 'Errore nel caricamento dei gruppi: $error';
  }

  @override
  String errorLoggingPracticeSession(String error) {
    return 'Errore nella registrazione della sessione di pratica: $error';
  }

  @override
  String errorPerformingCleanup(String error) {
    return 'Errore durante la pulizia: $error';
  }

  @override
  String errorPlayingAudio(String error) {
    return 'Errore nella riproduzione dell\'audio: $error';
  }

  @override
  String errorProcessingFile(String fileName, String error) {
    return 'Errore nell\'elaborazione di $fileName: $error';
  }

  @override
  String errorSavingGroupOrder(String error) {
    return 'Errore nel salvataggio dell\'ordine del gruppo: $error';
  }

  @override
  String errorSavingSettings(String error) {
    return 'Errore nel salvataggio delle impostazioni: $error';
  }

  @override
  String errorScanningUnusedMedia(String error) {
    return 'Errore nella scansione dei media non utilizzati: $error';
  }

  @override
  String errorSharing(String error) {
    return 'Errore nella condivisione: $error';
  }

  @override
  String errorTogglingGroupVisibility(String error) {
    return 'Errore nell\'attivazione/disattivazione della visibilità del gruppo: $error';
  }

  @override
  String errorUpdatingGroup(String error) {
    return 'Errore nell\'aggiornamento del gruppo: $error';
  }

  @override
  String errorUpdatingPracticeSession(String error) {
    return 'Errore nell\'aggiornamento della sessione di pratica: $error';
  }

  @override
  String errorWithDetails(String error) {
    return 'Errore: $error';
  }

  @override
  String get errorsEncountered => 'Errori incontrati:';

  @override
  String get existingBackupFound => 'Backup Esistente Trovato';

  @override
  String get fDRoid => 'F-Droid';

  @override
  String get fDroidOrgMyrepertoirapp => 'f-droid.org/.../myrepertoirapp';

  @override
  String failedToDeleteFile(String fileName, String error) {
    return 'Impossibile eliminare $fileName: $error';
  }

  @override
  String get failedToFetchThumbnail => 'Impossibile recuperare la miniatura.';

  @override
  String get failedToGeneratePdfThumbnail =>
      'Impossibile generare la miniatura PDF.';

  @override
  String get failedToGenerateVideoThumbnail =>
      'Impossibile generare la miniatura del video.';

  @override
  String get failedToInitializeBackupSettings =>
      'Impossibile inizializzare le impostazioni di backup';

  @override
  String failedToLoadGroups(String error) {
    return 'Impossibile caricare i gruppi: $error';
  }

  @override
  String failedToLoadMusicPieces(String error) {
    return 'Impossibile caricare i pezzi musicali: $error';
  }

  @override
  String failedToUpdateImage(String error) {
    return 'Impossibile aggiornare l\'immagine: $error';
  }

  @override
  String get fetching => 'Recupero in corso...';

  @override
  String get fileCategories => 'Categorie File';

  @override
  String get fileExplorer => 'Esplora File';

  @override
  String get fileMissing => 'File mancante';

  @override
  String get fileNotFoundToShare => 'File non trovato da condividere.';

  @override
  String fileTypeAndName(String fileType, String fileName) {
    return '$fileType • $fileName';
  }

  @override
  String get fileTypes => 'Tipi di File';

  @override
  String get filesDeleted => 'File Eliminati';

  @override
  String get filesToDelete => 'File da eliminare';

  @override
  String get filterByTags => 'Filtra per Tag';

  @override
  String get filterOptions => 'Opzioni Filtro';

  @override
  String filterSaved(String name) {
    return 'Filtro \"$name\" salvato';
  }

  @override
  String get foldAll => 'Ripiega Tutto';

  @override
  String get folderSelectionCancelled => 'Selezione cartella annullata';

  @override
  String get folderSelectionCancelled2 => 'Selezione cartella annullata.';

  @override
  String get forward1sHoldFor50msFineSkip =>
      'Avanti 1s (Tieni premuto per salto fine 50ms)';

  @override
  String get forward1sHoldForFrameSkip =>
      'Avanti 1s (Tieni premuto per saltare frame)';

  @override
  String get forward5s => 'Avanti 5s';

  @override
  String get frequentlyAskedQuestions => 'Domande Frequenti';

  @override
  String get functionality => 'Funzionalità';

  @override
  String get galleryLayout => 'Layout Galleria';

  @override
  String get generalSettings => 'Impostazioni Generali';

  @override
  String get getPdfThumbnail => 'Ottieni miniatura PDF';

  @override
  String get getVideoThumbnail => 'Ottieni miniatura video';

  @override
  String get github => 'GitHub';

  @override
  String get githubComAdithyaJayanMyrepertoirapp =>
      'github.com/Adithya-Jayan/MyRepertoirApp';

  @override
  String get githubComMyrepertoirapp => 'github.com/.../MyRepertoirApp';

  @override
  String get go => 'Vai';

  @override
  String get goToPage => 'Vai a Pagina';

  @override
  String get gradient => 'Gradiente';

  @override
  String get gradientOverlay => 'Sovrapposizione Gradiente';

  @override
  String get grant => 'Consenti';

  @override
  String get groupByPiece => 'Raggruppa per Pezzo';

  @override
  String get groupByType => 'Raggruppa per Tipo';

  @override
  String groupItemCount(String groupName, int count) {
    return '$groupName ($count)';
  }

  @override
  String get groupName => 'Nome Gruppo';

  @override
  String groupPieceCount(String groupName, int count) {
    return '$groupName ($count)';
  }

  @override
  String get groups => 'Gruppi';

  @override
  String get guidesAndTroubleshooting => 'Guide e risoluzione dei problemi';

  @override
  String get help => 'Aiuto';

  @override
  String get helpAndFaq => 'Aiuto e FAQ';

  @override
  String get hideEmptyGroups => 'Nascondi Gruppi Vuoti';

  @override
  String get hold => 'Tieni Premuto';

  @override
  String get homeRepertoireApp => 'Home/RepertoireApp';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String get howFindPieceAnswer =>
      'Usa la barra di ricerca in cima alla schermata principale della libreria. Puoi cercare per titolo, artista/compositore o tag.';

  @override
  String get howFindPieceQuestion =>
      'Come faccio a trovare velocemente uno specifico pezzo musicale?';

  @override
  String get howOftenToCreateAutomaticBackups =>
      'Con che frequenza creare backup automatici';

  @override
  String get image => 'Immagine';

  @override
  String get imageUpdatedSuccessfully => 'Immagine aggiornata con successo';

  @override
  String get imageViewer => 'Visualizzatore Immagini';

  @override
  String get images => 'Immagini';

  @override
  String get information => 'Informazioni';

  @override
  String get initializingBackupSettings =>
      'Inizializzazione impostazioni di backup...';

  @override
  String get inspiredBy => 'Ispirato da';

  @override
  String get internalFileExplorer => 'Esplora File Interni';

  @override
  String get internalStorageRepertoireApp =>
      'Archiviazione Interna/RepertoireApp';

  @override
  String invalidAudioFileType(String extensions) {
    return 'Tipo di file audio non valido. Supportati: $extensions';
  }

  @override
  String get itemNameAlreadyExists => 'Un elemento con questo nome esiste già.';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '1 selezionato',
    );
    return '$_temp0';
  }

  @override
  String get justNow => 'Proprio ora';

  @override
  String get keepTrackOfSessionsAndStatus =>
      'Tieni traccia delle sessioni e dello stato';

  @override
  String get lastAutomaticBackup => 'Ultimo Backup Automatico';

  @override
  String get lastPracticed => 'Ultima Pratica';

  @override
  String lastPracticedAt(String date) {
    return 'Ultima pratica: $date';
  }

  @override
  String lastPracticedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return 'Ultima pratica: $_temp0';
  }

  @override
  String get lastPracticedToday => 'Ultima pratica: Oggi';

  @override
  String get lastPracticedYesterday => 'Ultima pratica: Ieri';

  @override
  String get learningProgress => 'Progresso di Apprendimento';

  @override
  String get letSGetYourRepertoireSetUpYouCanAlwaysChangeThese =>
      'Configuriamo il tuo repertorio. Puoi sempre cambiare queste impostazioni in seguito.';

  @override
  String get license => 'Licenza';

  @override
  String get light => 'Chiaro';

  @override
  String get lightPink => 'Rosa Chiaro';

  @override
  String get lightSalmon => 'Salmone Chiaro';

  @override
  String get link => 'Link';

  @override
  String get links => 'Link';

  @override
  String get loading => 'Caricamento...';

  @override
  String get localVideo => 'Video Locale';

  @override
  String get logFileDeleted => 'File di log eliminato.';

  @override
  String get logPractice => 'Registra Pratica';

  @override
  String get loggingAndDeveloperOptions => 'Logging e opzioni sviluppatore';

  @override
  String get searchMusicBrainz => 'Cerca su MusicBrainz';

  @override
  String get searchMusicBrainzDialogTitle => 'Cerca su MusicBrainz';

  @override
  String get noCoverArtAvailable =>
      'Nessuna copertina trovata per questa release';

  @override
  String musicBrainzSearchError(String error) {
    return 'Impossibile raggiungere MusicBrainz: $error';
  }

  @override
  String get lyrics => 'Testi';

  @override
  String get lyricsContent => 'Testi';

  @override
  String get searchLyrics => 'Cerca testi (lrclib.net)';

  @override
  String get searchLyricsDialogTitle => 'Cerca testi';

  @override
  String get trackNameLabel => 'Nome traccia';

  @override
  String get artistNameLabel => 'Nome artista';

  @override
  String get noLyricsAvailable => 'Nessun testo disponibile';

  @override
  String get noLyricsFound => 'Nessun risultato trovato';

  @override
  String lyricsSearchError(String error) {
    return 'Impossibile raggiungere lrclib.net: $error';
  }

  @override
  String get logsDeleted => 'Log eliminati.';

  @override
  String get longOverdue => 'Molto in ritardo';

  @override
  String get manageAndReorderGroups => 'Gestisci e riordina i gruppi';

  @override
  String manageFilter(String name) {
    return 'Gestisci Filtro: $name';
  }

  @override
  String get manageGroups => 'Gestisci Gruppi';

  @override
  String get manageTags => 'Gestisci Tag';

  @override
  String get manualBackupAndRestore => 'Backup e Ripristino Manuale';

  @override
  String get manuallyTriggerAnAutomaticBackup =>
      'Attiva manualmente un backup automatico';

  @override
  String get markdownContent => 'Contenuto Markdown';

  @override
  String get markdownText => 'Testo Markdown';

  @override
  String get maxCount => 'Conteggio Massimo';

  @override
  String get maximumNumberOfAutomaticBackupsToRetain =>
      'Numero massimo di backup automatici da conservare';

  @override
  String get media => 'Media';

  @override
  String get mediaName => 'Nome Media';

  @override
  String get midiChannelNames => 'Nomi Canali MIDI';

  @override
  String midiChannelNumber(int number) {
    return 'Ch $number:';
  }

  @override
  String get midiDesktopUnsupported =>
      'La riproduzione MIDI non è attualmente supportata su piattaforme desktop.';

  @override
  String midiFileNotFound(String path) {
    return 'File MIDI non trovato in $path';
  }

  @override
  String get midi => 'MIDI';

  @override
  String get midiPlaybackIsNotSupportedOnWeb =>
      'La riproduzione MIDI non è supportata sul Web.';

  @override
  String get mihon => 'Mihon';

  @override
  String get mintGreen => 'Verde Menta';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String missingBackupWarning(String date) {
    return 'Avviso: File di backup ultimo mancante (previsto in $date). Creazione nuovo backup.';
  }

  @override
  String get modifyGroup => 'Modifica Gruppo';

  @override
  String get modifyGroups => 'Modifica Gruppi';

  @override
  String get musicPieceUpdatedSuccessfully =>
      'Pezzo musicale aggiornato con successo.';

  @override
  String get musicPieces => 'Pezzi Musicali';

  @override
  String get musicRepertoireApp => 'Repertoire';

  @override
  String get needsAttention => 'Necessita di attenzione';

  @override
  String get never => 'Mai';

  @override
  String get neverPracticed => 'Mai praticato';

  @override
  String get newName => 'Nuovo Nome';

  @override
  String get newPieceTitle => 'Titolo Nuovo Pezzo';

  @override
  String get newStageName => 'Nome Nuova Fase';

  @override
  String get newTagName => 'Nome Nuovo Tag';

  @override
  String get newUpdateAvailable => 'Nuovo Aggiornamento Disponibile!';

  @override
  String get next => 'Successivo';

  @override
  String get no => 'No';

  @override
  String get noAppWasFoundToOpenTheLogFileWouldYouLike =>
      'Nessuna app trovata per aprire il file di log. Desideri condividerlo invece?';

  @override
  String get noAutomaticBackupsFound => 'Nessun backup automatico trovato.';

  @override
  String get noBookmarksAddedYet => 'Nessun segnalibro aggiunto ancora';

  @override
  String get noContributorsFound => 'Nessun contributore trovato.';

  @override
  String get noDurationRecorded => 'Nessuna durata registrata';

  @override
  String get noLogFileFound => 'Nessun file di log trovato.';

  @override
  String get noPiecesFound => 'Nessun pezzo trovato.';

  @override
  String get noPracticeSessionsRecordedYetTapThePlusButtonToAddYour =>
      'Nessuna sessione di pratica registrata ancora.\nTocca il pulsante + per aggiungere la tua prima sessione di pratica.';

  @override
  String get noShareableFilesSelected =>
      'Nessun file condivisibile selezionato.';

  @override
  String get noStagesDefined => 'Nessuna fase definita';

  @override
  String get noStorageLocationSet =>
      'Nessun percorso di archiviazione impostato';

  @override
  String get noTagFiltersActive => 'Nessun filtro tag attivo';

  @override
  String get noTagGroupsFoundInYourLibrary =>
      'Nessun gruppo di tag trovato nella tua libreria.';

  @override
  String get noTagsInThisGroup => 'Nessun tag in questo gruppo.';

  @override
  String get noUnusedFilesFoundToCleanUp =>
      'Nessun file non utilizzato trovato da pulire.';

  @override
  String get noVisibleGroups => 'Nessun gruppo visibile.';

  @override
  String get normal => 'Normale';

  @override
  String get notInLast30Days => 'Non negli ultimi 30 giorni';

  @override
  String get notSet => 'Non impostato';

  @override
  String get noteFDRoidMayTakeAFewDaysToReflectThe =>
      'Nota: F-Droid potrebbe richiedere alcuni giorni per riflettere la nuova versione.';

  @override
  String get notesOptional => 'Note (opzionali)';

  @override
  String get notifyNewReleases => 'Notifica Nuove Versioni';

  @override
  String get numberOfBackupsToKeep => 'Numero di Backup da Conservare';

  @override
  String numberedStage(int number, String stage) {
    return '$number. $stage';
  }

  @override
  String get openLink => 'Apri Link';

  @override
  String get openLogs => 'Apri Log';

  @override
  String get openingFolderSelector => 'Apertura selettore cartella...';

  @override
  String get organizeYourMusicPiecesAttachMediaAndTrackYourPracticeJourney =>
      'Organizza i tuoi pezzi, allega media e traccia il tuo percorso di pratica.';

  @override
  String get other => 'Altro';

  @override
  String get outline => 'Contorno';

  @override
  String get outlineText => 'Testo Contorno';

  @override
  String pageIndicator(int currentPage, int totalPages) {
    return '$currentPage / $totalPages';
  }

  @override
  String pageNumberHint(int totalPages) {
    return 'Inserisci numero pagina (1-$totalPages)';
  }

  @override
  String get partialSuccess => 'Successo Parziale';

  @override
  String get pathOrUrl => 'Percorso o URL';

  @override
  String pathValue(String path) {
    return 'Percorso: $path';
  }

  @override
  String get pause => 'Pausa';

  @override
  String get pdf => 'PDF';

  @override
  String get pdfFilePathIsEmpty => 'Il percorso del file PDF è vuoto';

  @override
  String get pdfThumbnailGeneratedSuccessfully =>
      'Miniatura PDF generata con successo!';

  @override
  String get pdfViewer => 'Visualizzatore PDF';

  @override
  String get pdfs => 'PDF';

  @override
  String get personalization => 'Personalizzazione';

  @override
  String get percentage => 'Percentuale';

  @override
  String get physicalView => 'Vista Fisica';

  @override
  String get pieceDuplicatedSuccessfully => 'Pezzo duplicato con successo';

  @override
  String get pitch => 'Pitch:';

  @override
  String get play => 'Riproduci';

  @override
  String get playbackSpeed => 'Velocità di Riproduzione';

  @override
  String get pleaseEnterATitle => 'Inserisci un titolo';

  @override
  String get pleaseGenerateAThumbnailFirst => 'Genera prima una miniatura.';

  @override
  String get pleaseUseTheAndroidWindowsOrLinuxVersionForMidiSupport =>
      'Utilizza la versione Android, Windows o Linux per il supporto MIDI.';

  @override
  String practiceCountLabel(int count) {
    return 'Conteggio pratica: $count';
  }

  @override
  String practiceLogsForPiece(String pieceTitle) {
    return 'Log Pratica - $pieceTitle';
  }

  @override
  String get practiceNotes => 'Note di Pratica';

  @override
  String get practiceOptions => 'Opzioni di Pratica';

  @override
  String get practiceSessionDeletedSuccessfully =>
      'Sessione di pratica eliminata con successo';

  @override
  String get practiceSessionLoggedSuccessfully =>
      'Sessione di pratica registrata con successo';

  @override
  String get practiceSessionUpdatedSuccessfully =>
      'Sessione di pratica aggiornata con successo';

  @override
  String get practiceStagesAndStatistics => 'Fasi di pratica e statistiche';

  @override
  String get practiceStatus => 'Stato di Pratica';

  @override
  String get practiceSummary => 'Riepilogo Pratica';

  @override
  String get practiceTimeStats => 'Statistiche Tempo di Pratica';

  @override
  String get practiceTracking => 'Tracciamento Pratica';

  @override
  String get practicedRecently => 'Praticato di recente';

  @override
  String get progress => 'Progresso';

  @override
  String progressPercent(int value) {
    return '$value%';
  }

  @override
  String get protectAndSyncYourData => 'Proteggi e sincronizza i tuoi dati';

  @override
  String get purgeUnusedMedia => 'Elimina Media Non Utilizzati';

  @override
  String get purging => 'Eliminazione in corso...';

  @override
  String get quickFilters => 'Filtri Rapidi';

  @override
  String get recentlyPracticed => 'Praticato di recente';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get releaseNotes => 'Note di Rilascio';

  @override
  String get removeMediaFilesNoLongerReferenced =>
      'Rimuovi i file multimediali non più referenziati';

  @override
  String removeTagFromGroupConfirmation(String tagName, String groupName) {
    return 'Rimuovi tag \"$tagName\" dal gruppo \"$groupName\" su tutti i pezzi?';
  }

  @override
  String get rename => 'Rinomina';

  @override
  String get renameBookmark => 'Rinomina Segnalibro';

  @override
  String get renameFile => 'Rinomina File';

  @override
  String get renameFileWarning =>
      'AVVISO: La ridenominazione dei file potrebbe interrompere i link se non gestita correttamente. L\'app tenterà di aggiornare automaticamente tutti i riferimenti dei pezzi.';

  @override
  String get renameGroup => 'Rinomina Gruppo';

  @override
  String renameMedia(String name) {
    return 'Rinomina: $name';
  }

  @override
  String renameNamedItem(String name) {
    return 'Rinomina \"$name\"';
  }

  @override
  String get renameQuickFilter => 'Rinomina Filtro Rapido';

  @override
  String get renameStage => 'Rinomina Fase';

  @override
  String get renameTagGroup => 'Rinomina Gruppo di Tag';

  @override
  String renameTagInGroup(String groupName) {
    return 'Rinomina Tag in \"$groupName\"';
  }

  @override
  String get renamedSuccessfully => 'Rinominato con successo.';

  @override
  String get reorderMediaAnswer =>
      'Nella schermata Modifica Pezzo, usa gli handle di trascinamento a sinistra degli elementi multimediali per riordinarli.';

  @override
  String get reorderMediaQuestion => 'Come posso riordinare i media o i tag?';

  @override
  String get reset => 'Ripristina';

  @override
  String get resetControls => 'Ripristina Controlli';

  @override
  String get resetZoom => 'Ripristina Zoom';

  @override
  String get restore => 'Ripristina';

  @override
  String get restoreCancelled => 'Ripristino annullato.';

  @override
  String get restoreDataFromAPreviousBackup =>
      'Ripristina i dati da un backup precedente';

  @override
  String restoreFailed(String error) {
    return 'Ripristino non riuscito: $error';
  }

  @override
  String get restoreFailedStoragePathNotConfigured =>
      'Ripristino non riuscito: Percorso di archiviazione non configurato.';

  @override
  String get restoreFromLocalBackup => 'Ripristina da Backup Locale';

  @override
  String get restoreInProgress => 'Ripristino in corso...';

  @override
  String get restoreLatest => 'Ripristina Ultimo';

  @override
  String get restoreThisBackup => 'Ripristina questo backup';

  @override
  String get restoringBackup => 'Ripristino backup in corso...';

  @override
  String get restoringData => 'Ripristino dei dati in corso...';

  @override
  String get retry => 'Riprova';

  @override
  String revertedToDefaultStoragePath(String path) {
    return 'Ripristinato al percorso di archiviazione dell\'app predefinito: $path';
  }

  @override
  String get rewind1sHoldFor50msFineSkip =>
      'Riavvolgi 1s (Tieni premuto per salto fine 50ms)';

  @override
  String get rewind5s => 'Riavvolgi 5s';

  @override
  String get root => 'Root';

  @override
  String get runAutoBackupNow => 'Esegui Backup Automatico Ora';

  @override
  String get save => 'Salva';

  @override
  String get saveAll => 'Salva Tutto';

  @override
  String get saveAsQuickFilter => 'Salva come Filtro Rapido';

  @override
  String get saveQuickFilter => 'Salva Filtro Rapido';

  @override
  String get scanResults => 'Risultati Scansione';

  @override
  String get searchExistingPiece => 'Cerca Pezzo Esistente';

  @override
  String get searchItems => 'Cerca elementi...';

  @override
  String get searchTags => 'Cerca tag...';

  @override
  String get selectAFolder => 'Seleziona una cartella';

  @override
  String get selectAFolderWhereTheAppWillStoreItsFiles =>
      'Seleziona una cartella dove l\'app archivierà i suoi file:';

  @override
  String get selectColor => 'Seleziona Colore';

  @override
  String get selectManually => 'Seleziona Manualmente';

  @override
  String get selectOrderedTags => 'Seleziona Tag Ordinati';

  @override
  String selectedPathNotWritable(String error) {
    return 'Il percorso selezionato non è scrivibile: $error. Scegli una posizione diversa.';
  }

  @override
  String get selectedPieceNoLongerExists =>
      'Il pezzo selezionato non esiste più.';

  @override
  String semitonesValue(String value) {
    return '$value st';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get share => 'Condividi';

  @override
  String get shareExportBackup => 'Condividi/Esporta backup';

  @override
  String get shareLogFile => 'Condividi File di Log';

  @override
  String get showAll => 'Mostra Tutto';

  @override
  String get showDotPattern => 'Mostra Motivo Punteggiato';

  @override
  String get showDurationAndStatsInLogs =>
      'Mostra durata e statistiche nei log';

  @override
  String get showGradientBackground => 'Mostra Sfondo Gradiente';

  @override
  String get showLastPracticed => 'Mostra Ultima Pratica';

  @override
  String get showPracticeCount => 'Mostra Conteggio Pratica';

  @override
  String get showScrollControlsInTheViewer =>
      'Mostra controlli di scorrimento nel visualizzatore';

  @override
  String get silver => 'Argento';

  @override
  String get skip => 'Salta';

  @override
  String get skyBlue => 'Blu Cielo';

  @override
  String get someThemeChangesMayRequireAnAppRestartToTakeFullEffect =>
      'Alcuni cambiamenti di tema potrebbero richiedere un riavvio dell\'app per avere effetto completo.';

  @override
  String get sortOptions => 'Opzioni di Ordinamento';

  @override
  String get sourceCodeOnGithub => 'Codice Sorgente su GitHub';

  @override
  String get spaceFreed => 'Spazio Liberato';

  @override
  String get spaceToFree => 'Spazio da liberare';

  @override
  String get speed => 'Velocità:';

  @override
  String speedMultiplier(String speed) {
    return '${speed}x';
  }

  @override
  String get stageAlreadyExists => 'La fase esiste già';

  @override
  String stageDefaultName(int number) {
    return 'Fase $number';
  }

  @override
  String get stageNameExists => 'Il nome della fase esiste';

  @override
  String get stages => 'Fasi:';

  @override
  String get stagesLabel => 'Fasi';

  @override
  String get stagesForPracticeIndicatorsDragToReorderDoubleTapNameToEdit =>
      'Fasi per gli indicatori di pratica. Trascina per riordinare. Doppio tap sul nome per modificare.';

  @override
  String get startApp => 'Avvia App';

  @override
  String get status => 'Stato';

  @override
  String get stay => 'Rimani';

  @override
  String get storageFolder => 'Cartella di Archiviazione';

  @override
  String get storageFolderSelectionNotAvailableOnThisPlatform =>
      'La selezione della cartella di archiviazione non è disponibile su questa piattaforma';

  @override
  String get storageFolderUpdatedSuccessfully =>
      'Cartella di archiviazione aggiornata con successo';

  @override
  String get storageLocation => 'Percorso di Archiviazione';

  @override
  String get storagePathUpdated => 'Percorso di archiviazione aggiornato.';

  @override
  String get storagePermissionExplanation =>
      'Questa app ha bisogno dell\'accesso \"A tutti i file\" (Gestisci Archiviazione Esterna) per gestire i backup nella cartella di archiviazione esterna scelta e per accedere ai file multimediali che colleghi da posizioni arbitrarie. Senza questo, il backup/ripristino e il collegamento di media esterni potrebbe non funzionare correttamente.';

  @override
  String get storagePermissionNeeded => 'Permesso di Archiviazione Necessario';

  @override
  String get success => 'Successo';

  @override
  String get supportAndResources => 'Supporto e Risorse';

  @override
  String get system => 'Sistema';

  @override
  String get systemAndMaintenance => 'Sistema e Manutenzione';

  @override
  String get systemDefault => 'Sistema Predefinito';

  @override
  String get tagGroups => 'Gruppi di Tag';

  @override
  String get tagName => 'Nome Tag';

  @override
  String get tagNameOrCommaSeparatedList =>
      'Nome tag (o lista separata da virgole)';

  @override
  String tagSetsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count set di tag attivi',
      one: '1 set di tag attivo',
    );
    return '$_temp0';
  }

  @override
  String get tagging => 'Etichettatura';

  @override
  String get taggingManagement => 'Gestione Etichettatura';

  @override
  String get tags => 'Tag';

  @override
  String get tagsAndCategories => 'Tag e Categorie';

  @override
  String get tan => 'Marrone Chiaro';

  @override
  String get tapToEdit => '(Tocca per modificare)';

  @override
  String get teal => 'Verde-Blu';

  @override
  String get textSearch => 'Ricerca Testo';

  @override
  String get theAppHasBeenUpdatedCheckTheReleaseNotesOnGithubFor =>
      'L\'app è stata aggiornata! Controlla le note di rilascio su GitHub per i dettagli.';

  @override
  String get theFollowingFilesAreNotReferencedByAnyPiecesAndCanBe =>
      'I seguenti file non sono referenziati da alcun pezzo e possono essere eliminati in sicurezza.';

  @override
  String get themeColorsAndLayout => 'Tema, colori e layout';

  @override
  String get themeMode => 'Modalità Tema';

  @override
  String get thisActionCannotBeUndoneMakeSureYouHaveABackupBefore =>
      'Questa azione non può essere annullata. Assicurati di avere un backup prima di procedere.';

  @override
  String get thisGroupIsEmpty => 'Questo gruppo è vuoto.';

  @override
  String
  get thisWillPermanentlyDeleteUnusedMediaFilesThatAreNoLongerReferenced =>
      'Questo eliminerà permanentemente i file multimediali non utilizzati che non sono più referenziati da alcun pezzo musicale.';

  @override
  String get thumbnail => 'Miniatura';

  @override
  String get thumbnailFetchedSuccessfully =>
      'Miniatura recuperata con successo!';

  @override
  String get thumbnailStyle => 'Stile Miniatura';

  @override
  String get thumbnailWidgetVisibleInEditModeOnly =>
      'Widget Miniatura (Visibile solo in Modalità Modifica)';

  @override
  String get title => 'Titolo';

  @override
  String get titleContains => 'Il titolo contiene...';

  @override
  String get transposeSemitones => 'Trasponi (semitoni)';

  @override
  String get transposeSemitonesHint => 'es. +2 o -3';

  @override
  String todayAt(String time) {
    return 'Oggi alle $time';
  }

  @override
  String get toggleControls => 'Attiva/Disattiva Controlli';

  @override
  String get totalFiles => 'File Totali';

  @override
  String get totalSessions => 'Sessioni Totali';

  @override
  String get totalSize => 'Dimensione Totale';

  @override
  String get totalTime => 'Tempo Totale';

  @override
  String get trackControls => 'Controlli Traccia';

  @override
  String get tracking => 'Tracciamento';

  @override
  String get trackingDisabled => 'Tracciamento Disabilitato';

  @override
  String get trackingEnabled => 'Tracciamento Abilitato';

  @override
  String get trackingStages => 'Fasi di Tracciamento';

  @override
  String get trans => 'Trans';

  @override
  String get trueBlackBackgroundInDarkMode =>
      'Sfondo nero vero in modalità scura';

  @override
  String get type => 'Tipo';

  @override
  String get ungrouped => 'Non Raggruppato';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get unknownArtist => 'Artista Sconosciuto';

  @override
  String unknownPiece(String pieceId) {
    return 'Pezzo Sconosciuto ($pieceId)';
  }

  @override
  String get unsavedChanges => 'Modifiche Non Salvate';

  @override
  String get unusedFiles => 'File Non Utilizzati';

  @override
  String get unusedMediaDetails => 'Dettagli Media Non Utilizzati';

  @override
  String get unusedSize => 'Dimensione Non Utilizzata';

  @override
  String get update => 'Aggiorna';

  @override
  String get updateAll => 'Aggiorna Tutto?';

  @override
  String updateTagGroupColorQuestion(String groupName) {
    return 'Desideri aggiornare il colore del gruppo di tag \"$groupName\" su tutti i pezzi?';
  }

  @override
  String updatedToVersion(String version) {
    return 'Aggiornato a v$version';
  }

  @override
  String get updates => 'Aggiornamenti';

  @override
  String get updatesAreManagedByTheGooglePlayStore =>
      'Gli aggiornamenti sono gestiti dal Google Play Store.';

  @override
  String get urlIsEmpty => 'L\'URL è vuoto';

  @override
  String get useOledBlack => 'Usa Nero OLED';

  @override
  String get useThePlusSignToAddMedia =>
      'Usa il segno \'+\' per aggiungere media';

  @override
  String usedInPieces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pezzi',
      one: '1 pezzo',
    );
    return 'Utilizzato in $_temp0';
  }

  @override
  String get version => 'Versione';

  @override
  String get versionAndContributorInfo => 'Info versione e contributori';

  @override
  String versionAvailable(String version) {
    return 'La versione $version è disponibile.';
  }

  @override
  String get video => 'Video';

  @override
  String get videoControls => 'Controlli Video';

  @override
  String get videoFilePathIsEmpty => 'Il percorso del file video è vuoto';

  @override
  String get videoThumbnailGeneratedSuccessfully =>
      'Miniatura video generata con successo!';

  @override
  String get viewAllContributors => 'Visualizza Tutti i Contributori';

  @override
  String get viewLyrics => 'Visualizza testo';

  @override
  String get viewPdf => 'Visualizza PDF';

  @override
  String get viewUnusedFiles => 'Visualizza File Non Utilizzati';

  @override
  String get website => 'Sito Web';

  @override
  String get websiteAndDocumentation => 'Sito Web e Documentazione';

  @override
  String get welcome => 'Benvenuto!';

  @override
  String whatsNewInVersion(String version) {
    return 'Novità in v$version';
  }

  @override
  String get withinLast7Days => 'Negli ultimi 7 giorni';

  @override
  String get wouldYouLikeToDeleteTheExistingDebugLogs =>
      'Desideri eliminare i log di debug esistenti?';

  @override
  String get yellow => 'Giallo';

  @override
  String get yes => 'Sì';

  @override
  String get yesDelete => 'Sì, elimina';

  @override
  String yesterdayAt(String time) {
    return 'Ieri alle $time';
  }

  @override
  String get youAreOnTheLatestVersion => 'Sei sulla versione più recente.';

  @override
  String get youHaveUnsavedChangesAreYouSureYouWantToDiscardThem =>
      'Hai modifiche non salvate. Sei sicuro di voler scartarle?';

  @override
  String get yourMediaLibraryIsClean =>
      'La tua libreria multimediale è pulita!';

  @override
  String get zoomIn => 'Zoom Avanti';

  @override
  String get zoomOut => 'Zoom Indietro';
}
