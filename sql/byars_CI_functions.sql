Create FUNCTION [OF].byars_lower_95(
@x as float
)
RETURNS decimal (18,5)
AS
BEGIN
	RETURN (cast(@x as float) * (POWER( 1- (1/ (9.0*cast(@x as float))) - (1.959964 / (3.0 * SQRT(cast(@x as float)))), 3.0)))
END;

GO


CREATE FUNCTION [OF].byars_upper_95(
@x as float
)
RETURNS decimal (18,5)
AS
BEGIN
	RETURN ((cast(@x as float)+1) * (POWER( 1- (1/ (9.0*(cast(@x as float)+1))) + (1.959964 / (3.0 * SQRT((cast(@x as float)+1)))), 3.0)))
END;

