class_name TrainEmployeeCommand
extends RefCounted
## Oyuncu eylemi: stat eğitimi (stat verilir), sektör uzmanlaşması (sector verilir) ya da yazılım sertifikası
## (cert_in: araç alanı) (GDD 11.2, 11.3).

var employee_id: String
var stat: String
var sector: String
var cert_area: String


func _init(employee_in: String, stat_in: String = "", sector_in: String = "", cert_in: String = "") -> void:
	employee_id = employee_in
	stat = stat_in
	sector = sector_in
	cert_area = cert_in


func execute(sim: Simulation) -> String:
	if not cert_area.is_empty():
		return sim.staff.certify(sim.state, sim.economy, employee_id, cert_area)
	if not sector.is_empty():
		return sim.staff.specialize(sim.state, sim.economy, employee_id, sector)
	return sim.staff.train(sim.state, sim.economy, employee_id, stat)
