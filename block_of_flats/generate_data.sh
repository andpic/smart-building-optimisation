#/bin/bash

TIME_STEP="0.25"  # h
HORIZON="24"      # h
N_FLATS="20"

N_STEPS="$(awk  -v TIME_STEP=$TIME_STEP \
               -v HORIZON=$HORIZON \
               '{ ; } END { print int(HORIZON/TIME_STEP); } ' \
               /dev/null)"

# Generate cost
awk   -v N_STEPS=$N_STEPS \
      -v TIME_STEP=$TIME_STEP \
      ' BEGIN  { 
                  # Tariff ranges
                  TARIFF_A=0.14608; # £/kWh
                  TARIFF_B=0.18145; # £/kWh
                  TARIFF_C=0.24127; # £/kWh
               } 
               { ; } 
         END   { 
                  for(k=0; k<N_STEPS; k++)
                  {
                     TIME=k*TIME_STEP % 24;
                     if(TIME>=0 && TIME<7) 
                        print TARIFF_A; 
                     else if(TIME>=7 && TIME<14) 
                        print TARIFF_B; 
                     else if(TIME>=14 && TIME<16.5) 
                        print TARIFF_A; 
                     else if(TIME>=16.5 && TIME<19) 
                        print TARIFF_C; 
                     else if(TIME>=19 && TIME<21) 
                        print TARIFF_B; 
                     else if(TIME>=21 && TIME<24) 
                        print TARIFF_A;
                  }
               }' \
   /dev/null > "cost.dat"

# Generate DC load                 
awk   -v N_STEPS=$N_STEPS \
      -v TIME_STEP=$TIME_STEP \
      -v N_FLATS=$N_FLATS \
      ' BEGIN  { 
                  # High and low DC loads
                  HIGH_LOAD=0.17;   # kW
                  LOW_LOAD=0.05;    # kW
                  
                  # Time parameters for energy consumption
                  UP_START=13;
                  UP_END=17.5;
                  INC_RATE=(HIGH_LOAD-LOW_LOAD)/(UP_END-UP_START);
                  DOWN_START=21.5;
                  DOWN_END=24;
                  DEC_RATE=(LOW_LOAD-HIGH_LOAD)/(DOWN_END-DOWN_START);
               } 
               { ; } 
         END   { 
                  for(j=0; j<N_FLATS; j++)
                     for(k=0; k<N_STEPS; k++)
                     {
                        TIME=k*TIME_STEP % 24;
                        if(TIME<UP_START) 
                           printf "%3d\t%8d\t%e\n",j,k,LOW_LOAD*(1+0.1*rand()); 
                        else if(TIME>=UP_START && TIME<UP_END) 
                           printf "%3d\t%8d\t%e\n",j,k,(LOW_LOAD+(TIME-UP_START)*INC_RATE)*(1+0.1*rand()); 
                        else if(TIME>=UP_END && TIME<DOWN_START) 
                           printf "%3d\t%8d\t%e\n",j,k,HIGH_LOAD*(1+0.1*rand()); 
                        else if(TIME>=DOWN_START && TIME<DOWN_END) 
                           printf "%3d\t%8d\t%e\n",j,k,(HIGH_LOAD+(TIME-DOWN_START)*DEC_RATE)*(1+0.1*rand()); 
                        else if(TIME>=DOWN_END) 
                           printf "%3d\t%8d\t%e\n",j,k,LOW_LOAD*(1+0.1*rand()); 
                     }
               }' \
   /dev/null > "dc_load.dat"

# Generate AC load
awk   -v N_STEPS=$N_STEPS \
      -v TIME_STEP=$TIME_STEP \
      -v N_FLATS=$N_FLATS \
      ' BEGIN  { 
                  # High and low AC loads
                  HIGH_LOAD=3;      # kW
                  LOW_LOAD=0.2;     # kW
               } 
               { ; } 
         END   {  
                  for(j=0; j<N_FLATS; j++)
                     for(k=0; k<N_STEPS; k++)
                     {
                        TIME=k*TIME_STEP % 24;
                        if((TIME>7 && TIME <13) || (TIME>15 && TIME<21)) 
                           printf "%3d\t%8d\t%e\n",j,k,HIGH_LOAD*(1+0.1*rand()); 
                        else
                           if(rand()>=0.9)
                              printf "%3d\t%8d\t%e\n",j,k,LOW_LOAD+(HIGH_LOAD-LOW_LOAD)*rand();
                           else
                              printf "%3d\t%8d\t%e\n",j,k,LOW_LOAD*(1+0.1*rand()); 
                     }
               }' \
   /dev/null > "ac_load.dat"

# Generate PV output
awk   -v N_STEPS=$N_STEPS \
      -v TIME_STEP=$TIME_STEP \
      -v N_FLATS=$N_FLATS \
      ' BEGIN  { 
                  # High and low production
                  HIGH_PROD=0.3; # kW
                  LOW_PROD=0;    # kW
                  
                  # Time parameters for energy consumption
                  UP_START=7.5;
                  UP_END=11;
                  INC_RATE=(HIGH_PROD-LOW_PROD)/(UP_END-UP_START);
                  DOWN_START=13;
                  DOWN_END=16.25;
                  DEC_RATE=(LOW_PROD-HIGH_PROD)/(DOWN_END-DOWN_START);
               } 
               { ; } 
         END   { 
                  for(j=0; j<N_FLATS; j++)
                     for(k=0; k<N_STEPS; k++)
                     {
                        TIME=k*TIME_STEP % 24;
                        if(TIME<UP_START) 
                           printf "%3d\t%8d\t%e\n",j,k,LOW_PROD*(1+0.1*rand()); 
                        else if(TIME>=UP_START && TIME<UP_END) 
                           printf "%3d\t%8d\t%e\n",j,k,(LOW_PROD+(TIME-UP_START)*INC_RATE)*(1+0.1*rand()); 
                        else if(TIME>=UP_END && TIME<DOWN_START) 
                           printf "%3d\t%8d\t%e\n",j,k,HIGH_PROD*(1+0.1*rand()); 
                        else if(TIME>=DOWN_START && TIME<DOWN_END) 
                           printf "%3d\t%8d\t%e\n",j,k,(HIGH_PROD+(TIME-DOWN_START)*DEC_RATE)*(1+0.1*rand()); 
                        else if(TIME>=DOWN_END) 
                           printf "%3d\t%8d\t%e\n",j,k,LOW_PROD*(1+0.1*rand()); 
                     }
               }' \
   /dev/null > "pv_output.dat"
