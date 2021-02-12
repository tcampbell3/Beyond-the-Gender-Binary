* Set up
clear all
set more off
set maxvar 120000

/* LEARNING RATE ETA
http://www.dkriesel.com/_media/science/neuronalenetze-en-zeta2-2col-dkrieselcom.pdf
page 92

"Experience shows that good learning rate values are in the range of 0.01 ≤ η ≤ 0.9."

"During training, another stylistic device can be a variable learning rate: In the beginning, a large learning rate leads to good results, but later it results in inaccurate learning. A smaller learning rate is more time-consuming, but the result is more precise. Thus, during the learning process the learning rate needs to be decreased by one order of magnitude once or repeatedly. 

A common error (which also seems to be a very neat solution at first glance) is to continually decrease the learning rate. Here it quickly happens that the descent of the learning rate is larger than the ascent of a hill of the error function we are climbing. The result is that we simply get stuck at this ascent. Solution: Rather reduce the learning rate gradually as mentioned above."
*/



* Program neural network
do "Do Files/2 - Neural Net Program.do"

* Loop over neural-network specifications, global is defined in eahc subfile to run on seperate cores.
foreach c in $c_values {

	* Loop over years
	forvalues y=2014/2018{
		
		* Set Seed
		local seed = 123*`c'*`y'
		mata: rseed(`seed')
		set seed `seed'
		
		* Open training data
		use Data/DTA/Training_`y', clear
			
			* Define nueral networks for first year, retrain for following years
			if `y'==2014{
			
				* Remove collinear features
				_rmcoll x_cts_* nn_cat_* , force
				local vars = r(varlist)

				* Count features
				ds `vars' division
				local features=wordcount(r(varlist))

				* Define number of nodes in first and second layer
				local nodes1=round((`features'+2)/2+1)*`c'	// (number of attributes + number of classes)/2 + 1
				local nodes2=round(`nodes1'/2)

				* Define brain - one layer
				brain define, input(`vars' division) output(masculine) hidden(`nodes1')
			
			}
			else{
				
				* Open prior year neural-network to train
				local y2=`y'-1
				brain load "Tables_and_Figures/nn_`c'_1_`y2'"

			}
			
			* Train, predict, and save brain 
			timer clear 
			timer on 1 
			brain train, iter(500) eta(.9)	// Dataset is randomly sorted each training-cycle, decreasing eta
			brain save "Tables_and_Figures/nn_`c'_1_`y'"
			timer off 1
			timer list 1
			
			* Define brain - two layers
			if `y'==2014{
			
				brain define, input(`vars' division) output(masculine) hidden(`nodes1' `nodes2')
			
			}
			else{
				
				* Open prior year neural-network to train
				local y2=`y'-1
				brain load "Tables_and_Figures/nn_`c'_2_`y2'"

			}

			* Train, predict, and save brain
			timer on 2
			brain train, iter(500) eta(.9) // Dataset is randomly sorted each training-cycle with decreasing eta
			brain save "Tables_and_Figures/nn_`c'_2_`y'"
			timer off 2
			timer list 2
		
	}

}

exit, STATA clear
