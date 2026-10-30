enum FT { text, multi, check, choice }

class F {
  final String key, label;
  final FT type;
  final List<String> opts;
  const F(this.key, this.label, [this.type = FT.text, this.opts = const []]);
}

class Sec {
  final String title;
  final List<F> fields;
  final bool road; // sekcja hamowni drogowej
  const Sec(this.title, this.fields, {this.road = false});
}

class TabSpec {
  final String key, title, aiTopic;
  final bool ai, dyno;
  final List<Sec> secs;
  const TabSpec(this.key, this.title, this.secs,
      {this.ai = true, this.dyno = false, this.aiTopic = ''});
}

final _variants = [
  for (var i = 1; i <= 3; i++)
    Sec('Stage 1 – wariant $i', [
      F('v${i}_label', 'Etykieta skrzyni / napędu (np. Manual, S-Tronic, ZF)'),
      F('v${i}_result', 'Wynik KM / Nm'),
      F('v${i}_notes', 'Uwagi / limiter momentu / sprzęgło', FT.multi),
    ]),
];

final kTabs = <TabSpec>[
  TabSpec('read', 'Odczyt', aiTopic: 'odczyt i zapis ECU (metoda, procedura, ryzyka)', [
    Sec('Dane ECU i metoda', [
      F('ecu_family', 'Rodzina ECU (np. EDC17, MED17)'),
      F('ecu_location', 'Lokalizacja ECU w pojeździe', FT.multi),
      F('method', 'Metoda odczytu', FT.choice, ['OBD', 'VR', 'Bench', 'Boot']),
      F('device', 'Urządzenie do odczytu'),
      F('stabilizer', 'Stabilizator napięcia (min. napięcie, zasilacz)', FT.multi),
      F('fans', 'Wentylatory startują przy procedurze', FT.check),
    ]),
    Sec('Uwagi ogólne', [
      F('notes', 'Instrukcje, procedury, demontaż podszybia itp.', FT.multi),
    ]),
  ]),
  TabSpec('power', 'Moc', aiTopic: 'wyniki Stage 1 i ograniczenia (skrzynia, sprzęgło, limiter momentu)', [
    Sec('Moc i moment fabryczny (Seria)', [
      F('fact_hp', 'Moc seryjna KM'),
      F('fact_nm', 'Moment seryjny Nm'),
    ]),
    ..._variants,
    Sec('Notatki z modyfikacji', [F('notes', 'Ogólne notatki', FT.multi)]),
  ]),
  TabSpec('dyno', 'Hamownia', dyno: true, aiTopic: 'przygotowanie auta do hamowni rolkowej (ESP/ABS, pasy, 4x4)', [
    Sec('Przygotowanie do rolek', [
      F('esp_button', 'Przycisk ESP wystarczy', FT.check),
      F('side_smic', 'Intercoolery po bokach (boczne SMIC)', FT.check),
      F('abs_fuse', 'Wymaga wyjęcia bezpiecznika ABS/ESP', FT.check),
      F('fuse_where', 'Który bezpiecznik i gdzie (skrzynka, numer, amperaż)', FT.multi),
      F('straps', 'Punkty mocowania pasów / haczenia', FT.multi),
      F('proc_notes', 'Notatki z procedury (rolki, odpinanie 4x4 itp.)', FT.multi),
    ]),
    Sec('Hamownia drogowa', [
      F('road_notes', 'Masa pojazdu, paliwo, warunki pomiaru', FT.multi),
    ], road: true),
  ]),
  TabSpec('egr', 'EGR', aiTopic: 'wyłączenie EGR (co odpiąć, pułapki)', [
    Sec('EGR', [
      F('unplug', 'Co wypiąć (wtyczki, wiązki, zaślepki)', FT.multi),
      F('bottom_access', 'Dostęp do wtyczki tylko od spodu / z kanału', FT.check),
      F('dpf_works', 'Czy po wyłączeniu EGR działa DPF?', FT.check),
      F('notes', 'Notatki', FT.multi),
    ]),
  ]),
  TabSpec('dpf', 'DPF', aiTopic: 'wycięcie / wyłączenie DPF (czujniki, demontaż)', [
    Sec('DPF', [
      F('location', 'Lokalizacja', FT.choice, ['pod autem', 'za silnikiem']),
      F('difficulty', 'Trudność wycięcia', FT.choice, ['prosta', 'średnia', 'trudna']),
      F('lower_subframe', 'Wymaga opuszczenia sanek / skrzyni do demontażu', FT.check),
      F('unplug', 'Co odpiąć (czujniki temperatur, różnicy ciśnień)', FT.multi),
      F('notes', 'Notatki (uwagi mechaniczne, średnice rur, opaski)', FT.multi),
    ]),
  ]),
  TabSpec('adblue', 'AdBlue', aiTopic: 'wyłączenie AdBlue/SCR (co odpiąć, emulacja)', [
    Sec('AdBlue', [
      F('unplug', 'Co odpiąć (wtyczki, moduł SCR, bezpiecznik)', FT.multi),
      F('bottom_access', 'Dostęp do wtyczki tylko od spodu / z kanału', FT.check),
      F('cut_drain', 'Czy trzeba wycinać / opróżniać', FT.multi),
      F('notes', 'Notatki', FT.multi),
    ]),
  ]),
  TabSpec('other', 'Inne', ai: false, [
    Sec('Notatki warsztatowe i mechaniczne', [
      F('notes', 'Notatki', FT.multi),
    ]),
  ]),
];
