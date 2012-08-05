#!/usr/bin/env ruby

sleep_time = 5

$app_name = 'tempnotifier'
$temperature_limit = 60
$cpu_temperature_lines_begin = ['Physical id', 'Core']

def notify(header, body)
	system "notify-send -u critical -t 1 -a #{$app_name} \"#{header}\" \"#{body}\""	
end

def get_temperature_lines(sensor_output)
	cpu_temperatures = []

	is_temperature_line = false

	sensor_output.each_line do |output_line|
		is_temperature_line = false

		$cpu_temperature_lines_begin.each do |temp_begin|
			if output_line.start_with? temp_begin
				is_temperature_line = true
				cpu_temperatures << output_line
				#puts output_line
				break
			end
		end
	end

	cpu_temperatures
end

def prepare_alert_message(cpu_temperatures)
	current_temperature_regexp = /.*:\s+\+(\d+\.\d+).*/
	current_temperature_matches = []
	current_temperature = 0.0

	need_show_alert_message = false
	alert_message = ''

	cpu_temperatures.each do |temperature_line|
		current_temperature_matches = temperature_line.scan(current_temperature_regexp)
		if current_temperature_matches.length == 1 and current_temperature_matches[0].length == 1
			current_temperature = current_temperature_matches[0][0].to_f

			if current_temperature > $temperature_limit
				need_show_alert_message = true
				alert_message << temperature_line
			end
		end  
	end

	alert_message
end

def show_alert_message_if_need(alert_message)
	if !alert_message.empty?
		notify "Temperature alert (max: #{$temperature_limit}C)", alert_message
	end
end

while true
	sensor_output = %x[sensors]
	
	cpu_temperatures = get_temperature_lines sensor_output
	alert_message = prepare_alert_message cpu_temperatures
	show_alert_message_if_need alert_message	

	sleep sleep_time
end