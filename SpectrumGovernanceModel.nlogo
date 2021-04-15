;VERSION 2.0 06/06/2018
;Automated Spectrum Enforcement Grant
;Generating Events
;1695-1710MHz Band
;Incumbents: MetSat, Entrants: LTE Handsets (Connection to eNodeB)
;Protection Zones: Multi-tiered Incumbent Proctection Zones (MPIZ)
;NAZ=No Access Zone, LAZ=Limited Access Zone, UAZ=Unlimited access Zone

;Defining the Agents
breed[MetSats MetSat] ;Meteorogical Satellites
breed[Handsets Handset] ;Mobile Station
breed[eNodeBs eNodeB]  ;eNodeB


;Local Variables of Agents
MetSats-own[NAZ-events LAZ-events ChangeInZones]
Handsets-own[movement-probability perceptionNAZ perceptionLAZ risk-profile transmission-probability associatedEnodeB g-valueNAZ g-valueLAZ caught-probability captured notCaptured tx sanctioned? neighborInfluence]
eNodeBs-own[total-handsets]

;Global variables (Observer)
globals[NAZone risk-limit limit1 NAZTx UAZTx LAZTx LAZTxI TotalHandsets TotalEvents TotalTransmissions
ratioEvents TotalEventsNAZ TotalEventsLAZ NAZsize LAZsize DetectionRateNAZValue DetectionRateLAZValue EvaluationTime]


;SETUP AND GO

;=============================================================================================;
;=============================================================================================;
to setup
  clear-all ;Clean everything
  setup-MetSats
  setup-Handsets
  setup-eNodeBs
  setup-association
  setup-perception
  setup-zones
  setup-enforcementParameters
  set EvaluationTime (SimulationTime / 20)
  setup-statistics
  reset-ticks ;Reset ticks to 0
end

to go
  move-handsets
  setup-association
  clean-transmissions
  transmission
  setup-perception
  global-statistics
  if SelfEnforcement? [
  update-zones
  ]
  if SocialNetwork? [
  ask-neighbors
  ]
  tick
  if (ticks >= SimulationTime)[
  stop ;stop the program after the specified number of ticks
  ]
end


;=============================================================================================;
;=============================================================================================;


;GO FUNCTIONS
to update-zones
  if (LAZTxI > 0)[
    ask Metsats[
      set LAZ-events (LAZ-events + 1)
    ]
  ]

  if (NAZTx > 0)[
    ask Metsats[
      set NAZ-events (NAZ-events + 1)
    ]
  ]

  if ((ticks mod EvaluationTime) = 0)[
    ask Metsats [
      ifelse (NAZ-events > 0) [
        if (NAZsize < 1)[
          set NAZsize (NAZsize + 0.1)
          set NAZ-events 0
          set ChangeInZones (ChangeInZones + 1)
          draw-zone
          setup-enforcementParameters
          ask handsets [
            set perceptionNAZ (perceptionNAZ + (perceptionNAZ * 0.7))
          ]

        ]
      ]
      [
      if (NAZsize > 0.2 )[
      set NAZsize (NAZsize - 0.1)
      draw-zone
      setup-enforcementParameters
      set ChangeInZones (ChangeInZones + 1)
      ]
      ]
      ifelse (LAZ-events > 0) [
        if (LAZsize < 1)[
          set LAZsize (LAZsize + 0.1)
          set LAZ-events 0
          set ChangeInZones (ChangeInZones + 1)
          draw-zone
          setup-enforcementParameters
          ask handsets [
            set perceptionNAZ (perceptionNAZ + (perceptionNAZ * 0.7))
          ]

        ]
      ]
      [
      if (LAZsize > 0.2) [
      set LAZsize (LAZsize - 0.1)
      draw-zone
      setup-enforcementParameters
      set ChangeInZones (ChangeInZones + 1)
      ]
      ]
    ]
  ]

end

to draw-zone
    set NAZone (NAZsize + LAZsize)
      ask MetSats[
    ask patches in-radius (NAZone * 10)[
      set pcolor black
    ]
    ask patches  in-radius (NAZone * 7) [
      set pcolor yellow
    ]

  ask patches in-radius (NAZsize * 5) [
    set pcolor red
  ]



  ]
end

to ask-neighbors
  ask handsets with [pcolor = yellow] [
    ifelse any? other handsets in-radius SocialNetworkRadius with [sanctioned?] [
      set perceptionLAZ (perceptionLAZ + (perceptionLAZ * 0.3))
      set neighborInfluence (neighborInfluence + 1)
    ]
    [
    ;set perceptionLAZ (perceptionLAZ - random-normal 0.1 0.02)
    ]
  ]

ask handsets with [pcolor = red] [
    ifelse any? other handsets in-radius SocialNetworkRadius with [sanctioned?] [
      set perceptionNAZ (perceptionNAZ + (perceptionNAZ * 0.3))
      set neighborInfluence (neighborInfluence + 1)
    ]
    [
    ;set perceptionNAZ (perceptionNAZ - random-normal 0.1 0.02)
    ]
  ]
end

to setup-zones
  ifelse SelfEnforcement? [
    set NAZsize (InitialSize / 100)
    set LAZsize ((InitialSize - 0.1) / 100)
    set NAZone (((NAZsize) * 5) + ((LAZsize) * 7))
  ask MetSats[
    ask patches  in-radius (NAZone) [
      set pcolor yellow
    ]

  ask patches in-radius (((NAZsize) * 5)) [
    set pcolor red
  ]]
]
  [
  set NAZone (((NAZ / 100) * 5) + ((LAZ / 100) * 7))
  set NAZsize (NAZ / 100)
  set LAZsize (LAZ / 100)
  ask MetSats[
    ask patches  in-radius (NAZone) [
      set pcolor yellow
    ]

  ask patches in-radius (((NAZ / 100) * 5)) [
    set pcolor red
  ]]
  ]

end

to move-handsets
  ask Handsets[
    set movement-probability random 100
    if movement-probability < 30[
      rt random 1000 ;turn to the right
      fd 1;one step forward
    ]
    ]
end


to transmission


  ask Handsets with [pcolor = black][
    set transmission-probability random 100
    if transmission-probability <= 50 [
      set UAZTx UAZTx + 1
      set tx (tx + 1)
  ]
    ]


  ask Handsets with [pcolor = yellow][
    set transmission-probability random 100
    if transmission-probability <= 50[
      ifelse (LAZTx >= LAZThreshold) [
        if perceptionLAZ <= (1 / (1 + g-valueLAZ))[
          set LAZTxI LAZTxI + 1
          set LAZTx LAZTx + 1
          set tx (tx + 1)

          set caught-probability random 5
          ifelse (caught-probability <= (DetectionRateLAZValue * 100 ))[
            set captured (captured + 1)
            set sanctioned? true
            set perceptionLAZ (perceptionLAZ + (perceptionLAZ * 0.5))
            ]
            [set notCaptured (notCaptured + 1)
            set perceptionLAZ (perceptionLAZ - random-normal 0.1 0.02)
            set sanctioned? false
            ]

        ]
        ]
        [set LAZTx (LAZTx + 1)
        set tx (tx + 1)
  ]
      ]
    ]


  ask Handsets with [pcolor = red][
    set transmission-probability random 5
    if perceptionNAZ <= (1 / (1 + g-valueNAZ)) [
      set NAZTx NAZTx + 1
      set tx (tx + 1)
      set caught-probability random 10
      ifelse (caught-probability <= (DetectionRateLAZValue * 100) )[
        set captured (captured + 1)
        set sanctioned? true
        set perceptionLAZ (perceptionNAZ + (perceptionLAZ * 0.5))
            ]
            [set notCaptured (notCaptured + 1)
            set sanctioned? false
            set perceptionNAZ (perceptionNAZ - random-normal 0.1 0.02)
            ]

    ]
  ]
end





to clean-transmissions
  set UAZTx 0
  set NAZTx 0
  set LAZTx 0
  set LAZTxI 0
end


to global-statistics
  set TotalEvents (TotalEvents + NAZTx + LAZTxI)
  set TotalEventsNAZ (TotalEventsNAZ + NAZTx)
  set TotalEventsLAZ (TotalEventsLAZ + LAZTxI)
  set TotalTransmissions (TotalTransmissions + UAZTx + LAZTx + NAZTx)
  set ratioEvents TotalEvents / TotalTransmissions
end


;=============================================================================================;
;=============================================================================================;


;SETUP FUNCTIONS
;Meteorogical Satellites
to setup-statistics
  set TotalEvents 0; Total Number of Interference Events
  set TotalTransmissions 1 ;Total Number of Transmissions in the System
  set ratioEvents 0  ;Ratio of events and total number of transmissions
  set TotalEventsNAZ 0 ; total events in NAZ
  set TotalEventsLAZ 0 ; total events in LAZ
end



to setup-MetSats
  create-MetSats 1
  ask MetSats [
  set LAZ-events 0
  set NAZ-events 0
  set ChangeInZones 0
  setxy 0 0
    set color green
    set shape "triangle 2"
    set size 3
  ]
end
;LTE Handsets
to setup-Handsets
  set totalHandsets (RiskAverse + RiskNeutral + RiskProne)
  create-Handsets totalHandsets
  set risk-limit 0
  set limit1 RiskAverse + RiskNeutral
  ask Handsets [
    set notCaptured 0
    set captured 0
    set tx 0
    set sanctioned? false
    set neighborInfluence 0
    setxy random-xcor random-ycor
    set shape "default"
    set size 1
    if risk-limit <= RiskAverse[
      set risk-profile "Averse"
      set risk-limit risk-limit + 1
      set color 74
    ]
    if risk-limit > RiskAverse and risk-limit <= limit1 + 1 [
      set risk-profile "Neutral"
      set risk-limit risk-limit + 1
      set color 94
    ]

    if risk-limit > limit1 + 1[
      set risk-profile "Prone"
      set risk-limit risk-limit + 1
      set color 124
    ]

  ]

end
;eNodeBs
to setup-eNodeBs
  create-eNodeBs 4
  ask eNodeB (TotalHandSets + 1) [
    setxy 10 10
    set shape "triangle"
    set size 2
    set color 64
  ]
  ask eNodeB (TotalHandSets + 2) [
    setxy -10 10
    set shape "triangle"
    set size 2
    set color 84
  ]
  ask eNodeB (TotalHandSets + 3) [
    setxy -10 -10
    set shape "triangle"
    set size 2
    set color 104
  ]
  ask eNodeB (TotalHandSets + 4) [
    setxy 10 -10
    set shape "triangle"
    set size 2
    set color 124
  ]
end

to setup-association
  ask Handsets[
  set associatedEnodeB min-one-of eNodeBs  [distance myself]
    if associatedEnodeB = (enodeb 301)[
    set color 64]
    if associatedEnodeB = (enodeb 302)[
    set color 84]
    if associatedEnodeB = (enodeb 303)[
    set color 104]
    if associatedEnodeB = (enodeb 304)[
    set color 124]
  ]
end

to setup-perception
  if PerceptionFunction = "Actual"[
    ask Handsets [
    set perceptionNAZ (DetectionRateNAZ / 100)
    set perceptionLAZ (DetectionRateLAZ / 100)
    ]
  ]
  if PerceptionFunction = "Perceived"[
    ask Handsets with [risk-profile = "Averse"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.25 0.02))
      set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.25 0.02))
    ]
    ask Handsets with [risk-profile = "Neutral"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.15 0.02))
    set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.15 0.02))
    ]
    ask Handsets with [risk-profile = "Prone"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.05 0.02))
    set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.05 0.02))
    ]
  ]
  if PerceptionFunction = "Actual+Random"[
    ask Handsets [
    set perceptionNAZ ((DetectionRateNAZ / 100)+ random-normal 0.05 0.01)
    set perceptionLAZ ((DetectionRateLAZ / 100)+ random-normal 0.05 0.01)
    ]
  ]
   if PerceptionFunction = "Perceived+Random"[
    ask Handsets with [risk-profile = "Averse"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.25 0.02) + random-normal 0.05 0.01)
      set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.25 0.02) + random-normal 0.05 0.01)
    ]
    ask Handsets with [risk-profile = "Neutral"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.15 0.02) + random-normal 0.05 0.01)
    set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.15 0.02) + random-normal 0.05 0.01)
    ]
    ask Handsets with [risk-profile = "Prone"][
    set perceptionNAZ ((DetectionRateNAZ / 100) + (random-normal 0.05 0.02) + random-normal 0.05 0.01)
    set perceptionLAZ ((DetectionRateLAZ / 100) + (random-normal 0.05 0.02) + random-normal 0.05 0.01)
    ]
  ]
    if PerceptionWeight [
      ask Handsets [
      set perceptionNAZ (1 - (((1 - perceptionNAZ) ^ 0.63)/(((perceptionNAZ * 0.63) + ((1 - perceptionNAZ) ^ 0.63)) ^ (1 / 0.63))))
      set perceptionLAZ (1 - (((1 - perceptionLAZ) ^ 0.63)/(((perceptionLAZ * 0.63) + ((1 - perceptionLAZ) ^ 0.63)) ^ (1 / 0.63))))
      ]
    ]
end

to setup-enforcementParameters
  ifelse SelfEnforcement?[
    set DetectionRateNAZValue (((DetectionEffectivity / 100) * 0.2 ) / NAZsize)
    set DetectionRateLAZValue (((DetectionEffectivity / 100) * 0.2 ) / LAZsize)

  ]
  [
  set DetectionRateNAZValue (DetectionRateNAZ / 100)
  set DetectionRateLAZValue (DetectionRateLAZ / 100)
  ;set NAZsize (NAZ / 100)
  ;set LAZsize (LAZ / 100)
  ]

  ask Handsets[
  set g-valueNAZ (((PenaltyRate) * (DetectionRateNAZValue / 1))/((1 + (AverageDiscountRate / 100)) ^ AdjudicationTime ))
  set g-valueLAZ (((PenaltyRate) * (DetectionRateNAZValue / 1))/((1 + (AverageDiscountRate / 100)) ^ AdjudicationTime ))
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
208
6
666
465
-1
-1
8.824
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
Time Periods
30.0

BUTTON
6
10
206
43
Initial-Setup(Reset)
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
431
201
464
NAZ
NAZ
1
100
100.0
1
1
%
HORIZONTAL

SLIDER
8
468
201
501
LAZ
LAZ
1
100
100.0
1
1
%
HORIZONTAL

BUTTON
7
46
206
106
Start/Stop/ReStart
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
441
794
507
854
RiskAverse
100.0
1
0
Number

INPUTBOX
577
794
639
854
RiskProne
100.0
1
0
Number

INPUTBOX
507
794
579
854
RiskNeutral
100.0
1
0
Number

TEXTBOX
213
18
478
36
Automated Spectrum Enforcement Version 2.0
11
9.9
1

PLOT
668
10
1323
219
Transmissions
Time
Number of Transmission
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"NAZTx" 1.0 0 -2674135 true "" "plot NAZTx"
"LAZTxI" 1.0 0 -1184463 true "" "plot LAZTxI"

INPUTBOX
8
505
200
565
LAZThreshold
5.0
1
0
Number

MONITOR
922
224
1113
285
Total Interference Events
TotalEvents
0
1
15

MONITOR
668
224
914
285
Total Number of Transmissions
TotalTransmissions
17
1
15

MONITOR
1116
224
1330
285
Ratio Events/Transmissions
ratioEvents
10
1
15

PLOT
667
287
1482
458
Ratio of Events
Time
Ratio of Events
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Ratio All Events" 1.0 0 -955883 true "" "plot ratioEvents"
"Ratio NAZ" 1.0 0 -13840069 true "" "plot (TotalEventsNAZ / TotalTransmissions)"
"Ratio LAZ" 1.0 0 -1184463 true "" "plot (TotalEventsLAZ / TotalTransmissions)"

MONITOR
1329
155
1484
216
Ratio NAZ Events
(TotalEventsNAZ / TotalTransmissions)
10
1
15

MONITOR
1332
224
1483
285
Ratio LAZ Events
(TotalEventsLAZ / TotalTransmissions)
10
1
15

PLOT
212
465
662
599
Number of Handsets in each Zone
Number
Time
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"UAZ" 1.0 0 -16777216 true "" "plot (count handsets with [pcolor = black]) "
"LAZ" 1.0 0 -1184463 true "" "plot (count handsets with [pcolor = yellow]) "
"NAZ" 1.0 0 -2674135 true "" "plot (count handsets with [pcolor = red]) "

CHOOSER
10
125
204
170
PerceptionFunction
PerceptionFunction
"Actual" "Perceived" "Actual+Random" "Perceived+Random"
3

SWITCH
10
175
205
208
PerceptionWeight
PerceptionWeight
1
1
-1000

SLIDER
6
358
200
391
DetectionRateNAZ
DetectionRateNAZ
10
100
75.0
1
1
%
HORIZONTAL

SLIDER
10
664
204
697
PenaltyRate
PenaltyRate
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
6
587
203
620
AverageDiscountRate
AverageDiscountRate
0
50
50.0
1
1
%
HORIZONTAL

SLIDER
8
627
203
660
AdjudicationTime
AdjudicationTime
0
10
10.0
1
1
Time Periods
HORIZONTAL

SLIDER
8
396
200
429
DetectionRateLAZ
DetectionRateLAZ
10
100
75.0
1
1
%
HORIZONTAL

TEXTBOX
10
111
160
129
Mobile Stations Perception
11
24.0
1

TEXTBOX
9
216
202
244
Self-Enforcement (Negotiation)\n
11
24.0
1

SWITCH
7
233
201
266
SelfEnforcement?
SelfEnforcement?
0
1
-1000

SLIDER
216
792
417
825
SimulationTime
SimulationTime
1000
10000
200.0
1000
1
Time Periods
HORIZONTAL

SLIDER
5
305
200
338
DetectionEffectivity
DetectionEffectivity
10
100
100.0
10
1
%
HORIZONTAL

PLOT
669
462
1066
612
Automatic Sizing Parameters
Time
%
0.0
5000.0
0.0
100.0
false
true
"" ""
PENS
"DetectionRateNAZ" 1.0 0 -14454117 true "" "plot (DetectionRateNAZValue * 100)"
"DetectionRateLAZ" 1.0 0 -14439633 true "" "plot (DetectionRateLAZValue * 100)"
"NAZSize" 1.0 0 -2674135 true "" "plot (NAZsize * 100)"
"LAZSize" 1.0 0 -1184463 true "" "plot (LAZsize * 100)"

PLOT
213
603
662
753
Enforcement Perception
Perception
Number of Handsets
0.0
10.0
0.0
100.0
true
true
"set-plot-x-range 0 1\n" ""
PENS
"Perception NAZ" 1.0 1 -14454117 true "" "set-histogram-num-bars 20\nhistogram [perceptionNAZ] of handsets"
"Perception LAZ" 1.0 1 -5825686 true "" "set-histogram-num-bars 20\nhistogram [perceptionLAZ] of handsets"

PLOT
672
619
1064
769
Number of Handsets Captured/Not Captured
Distribution
Number of Handsets
0.0
10.0
0.0
25.0
false
true
"set-plot-x-range 0 100\nset-plot-y-range 0 25" ""
PENS
"Captured" 1.0 1 -13840069 true "" "set-histogram-num-bars 100\nhistogram [Captured] of handsets"
"Not Captured" 1.0 1 -2674135 true "" "set-histogram-num-bars 100\nhistogram [notCaptured] of handsets"

SWITCH
214
755
426
788
SocialNetwork?
SocialNetwork?
1
1
-1000

SLIDER
435
756
663
789
SocialNetworkRadius
SocialNetworkRadius
1
4
4.0
1
1
NIL
HORIZONTAL

PLOT
1075
620
1477
770
NeighborInfluence
Influcene (# of times)
Number of Handsets
0.0
10.0
0.0
25.0
false
true
"set-plot-x-range 0 100\nset-plot-y-range 0 25" ""
PENS
"Handsets" 1.0 1 -7858858 true "" "set-histogram-num-bars 100\nhistogram [neighborInfluence] of handsets"

PLOT
1077
462
1475
612
Agent Perception
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Mean NAZ " 1.0 0 -2674135 true "" "plot mean [PerceptionNAZ] of handsets"
"Mean LAZ" 1.0 0 -1184463 true "" "plot mean [PerceptionLAZ] of handsets"
"Max NAZ" 1.0 0 -14070903 true "" "plot max [PerceptionNAZ] of handsets"
"Max LAZ" 1.0 0 -14439633 true "" "plot max [PerceptionLAZ] of handsets"
"Min LAZ" 1.0 0 -7500403 true "" "plot min [PerceptionLAZ] of handsets"
"Min NAZ" 1.0 0 -955883 true "" "plot min [PerceptionNAZ] of handsets"

SLIDER
8
270
204
303
InitialSize
InitialSize
20
100
100.0
10
1
%
HORIZONTAL

TEXTBOX
10
344
196
372
Thrid-party Characteristics\n
11
24.0
1

TEXTBOX
17
574
204
602
General Enforcement Conditions
11
24.0
1

MONITOR
683
773
841
818
Detection Rate LAZ
DetectionRateLAZValue
17
1
11

MONITOR
851
774
983
819
Detection Rate NAZ
DetectionRateNAZValue
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="GovernmentEnforcement" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>TotalTransmissions</metric>
    <metric>TotalEvents</metric>
    <metric>TotalEventsLAZ</metric>
    <metric>(TotalEventsLAZ / TotalTransmissions)</metric>
    <metric>TotalEventsNAZ</metric>
    <metric>(TotalEventsNAZ / TotalTransmissions)</metric>
    <metric>mean [PerceptionNAZ] of handsets</metric>
    <metric>mean [PerceptionLAZ] of handsets</metric>
    <metric>(DetectionRateNAZValue * 100)</metric>
    <metric>(DetectionRateLAZValue * 100)</metric>
    <metric>(NAZsize * 100)</metric>
    <metric>(LAZsize * 100)</metric>
    <metric>mean [Captured] of handsets</metric>
    <metric>max [Captured] of handsets</metric>
    <metric>mean [notCaptured] of handsets</metric>
    <metric>max [notCaptured] of handsets</metric>
    <metric>UAZTx</metric>
    <metric>NAZTx</metric>
    <metric>LAZTx</metric>
    <enumeratedValueSet variable="RiskAverse">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RiskNeutral">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RiskProne">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LAZThreshold">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NAZ">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LAZ">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SimulationTime">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DetectionRateNAZ">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DetectionRateLAZ">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PerceptionFunction">
      <value value="&quot;Actual+Random&quot;"/>
      <value value="&quot;Perceived+Random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PerceptionWeight">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfEnforcement?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AverageDiscountRate">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AdjudicationTime">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PenaltyRate">
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SocialNetwork?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SocialNetworkRadius">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SelfEnforcement" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>TotalTransmissions</metric>
    <metric>TotalEvents</metric>
    <metric>TotalEventsLAZ</metric>
    <metric>(TotalEventsLAZ / TotalTransmissions)</metric>
    <metric>TotalEventsNAZ</metric>
    <metric>(TotalEventsNAZ / TotalTransmissions)</metric>
    <metric>mean [PerceptionNAZ] of handsets</metric>
    <metric>mean [PerceptionLAZ] of handsets</metric>
    <metric>(DetectionRateNAZValue * 100)</metric>
    <metric>(DetectionRateLAZValue * 100)</metric>
    <metric>(NAZsize * 100)</metric>
    <metric>(LAZsize * 100)</metric>
    <metric>mean [Captured] of handsets</metric>
    <metric>max [Captured] of handsets</metric>
    <metric>mean [notCaptured] of handsets</metric>
    <metric>max [notCaptured] of handsets</metric>
    <metric>UAZTx</metric>
    <metric>NAZTx</metric>
    <metric>LAZTx</metric>
    <enumeratedValueSet variable="RiskAverse">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RiskNeutral">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RiskProne">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LAZThreshold">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SimulationTime">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PerceptionFunction">
      <value value="&quot;Actual+Random&quot;"/>
      <value value="&quot;Perceived+Random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PerceptionWeight">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SelfEnforcement?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AverageDiscountRate">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="AdjudicationTime">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PenaltyRate">
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SocialNetwork?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SocialNetworkRadius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialSize">
      <value value="20"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DetectionEffectivity">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
