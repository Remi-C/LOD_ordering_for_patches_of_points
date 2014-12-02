SELECT count(*)
FROM   acquisition_tmob_012013.riegl_pcpatch_space
WHERE pc_numpoints(patch)>100


SELECT count(*)
FROM   acquisition_tmob_012013.riegl_pcpatch_space
WHERE points_per_level is not null ;

--537k

 --17h 21 : 32716
-- 17h 23 : 34538
--17h38 : 49773
-- 17h49  : 63438
--18h04 : 85790
-- 18h14 : 102326
-- 18h26 : 118452
-- 18h33 : 125935
-- 18h39 : 132254
--18h56 : 147251
-- 19h28 : 184386
-- 20h00 : 214682

 SELECT (118452- 32716)/((48) * 60.0)

 SELECT 537000/(16*3600)