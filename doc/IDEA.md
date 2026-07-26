# Quadrim

Quadrim is een spel waar gebruikers om de beurt een 'pion' in eigen kleur zetten in een leeg veld in een kubus van 4 bij 4 bij 4.
Doel van het spel is om als eerste 4 pionnen van eigen kleur op een rij te hebben. 
Dit mag horizontaal, vertikaal maar ook diagonaal door alle lagen in de kubus.

## Beschikbaarheid

Het is gewenst om het spel op zoveel mogelijk platformen beschikbaar te maken en in ieder geval voor iOS en Android.

Een eerste idee is om de software stack te baseren op:
Flutter App
Firestore
Cloud Function (trigger)
Firebase Cloud Messaging
Android + iOS devices (en web + win en osx apps)

## Visueel

### Het hoofdscherm

Bij opstarten ziet de speler de volgende onderdelen op het scherm:
- een statistieken overzicht van de gespeelde spellen (aantal gewonnen, verloren en gelijkspel, ELO rating)
- een lijst met actieve spelen
- een grote knop aanwezig om een nieuw spel te starten. 
- een knop om de tutorial te starten.
- een lijst met gespeelde spelen. 

Bij het starten van een nieuw spel kan de speler kiezen of hij tegen een andere speler of tegen de computer wil spelen.

### Tutorial

Een eerste keer dat een speler het spel start, zal er een korte tutorial worden getoond waarin de spelregels en de bediening van het spel wordt uitgelegd. De tutorial kan op elk moment opnieuw worden gestart vanuit het hoofdscherm.

### Het actieve spel

Afhankelijk van de scherm grootte en de oriëntatie van het apparaat, zal het actieve spel op een andere manier worden weergegeven.

### kleine schermen (telefoonts)
- weergave altijd in portret modus.
- Naam van tegenstander is zichtbaar boven het speelbord en bij klikken op die naam zie je details van die speler.

### Grote schermen (tablets en laptops)
- weergave altijd in landschap modus.
- Links zie je het speelbord en rechts zie je details van je eigen profiel en de tegenstander. (algemene details plus details van spelen tegen elkaar)

### Het speelbord

Het speelbord moet duidelijk en overzichtelijk zijn. Het moet duidelijk zijn welke velden al bezet zijn en welke nog vrij zijn.
Voor de visualisatie van de kubus kan gebruik gemaakt worden van een 3D visualisatie waarbij de 4 lagen van de kubus zichtbaar zijn als 4 aparte 2D vlakken (paralelogram om de diepte aan te geven). De gebruiker ziet dat een visualisatie van de gehele kubus.


## De Computer game engine

De Computer game engine zal de volgende evaluaties op deze volgorde uitvoeren. Eerst zal naar afgedwongen zetten worden gekeken en daarna naar berekende zetten.
Onderstaande regels zijn opgesteld op basis van ervaring met het spel en zijn bedoeld om de computer een zo goed mogelijke tegenstander te maken.
Voor de berekende zetten kan het misschien haalbaar zijn om alle mogelijke zetten te evalueren en de beste te kiezen, maar dat is nog niet onderzocht.

### Strategische win/lose zetten
Ga de volgen regels op volgorde af en als aan een regel voldaan wordt, zet de pion daar, als er meer posities zijn voor die regel, bepaal de beste plek op basis van 'Berekende zetten'
- zijn er velden waardoor zelf 4 op een rij verkregen worden. 
- Is er ergens een leeg veld waardoor de ander 4 op een rij verkregen kan worden. 
- Is er ergens een leeg veld waardoor er 2 maal 3 op een rij ontstaat waarbij op die rij het overgebleven veld nog leeg is. 
- Is er ergens een leeg veld waardoor de ander 2 maal 3 op een rij zou kunnen krijgen waarbij op die rij het overgebleven veld nog leeg is. 

### Berekende beste positie zetten
Ga de volgende regels op volgorde af en als aan een regel voldaan wordt, zet de pion daar, als er meerdere posities zijn voor die regel, neem dan de plek waar de meeste 2 of meer op een rij ontstaan. Als daar meerdere van zijn, kies dan willekeurig
- Is er een plek leeg in de 2 bij 2 bij 2 kubus in het midden van de grote kubus. 
- Is er een plek op een van de hoeken van de kubus beschikbaar.
