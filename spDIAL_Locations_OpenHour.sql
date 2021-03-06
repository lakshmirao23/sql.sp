USE [OntarioLive]
GO
/****** Object:  StoredProcedure [dbo].[spDIAL_Locations_OpenHour]    Script Date: 04/05/2018 09:37:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Branch Manager:  
--Mobile Number:  
--Email:  
 
--Day Sun Mon Tue Wed Thu Fri Sat 
--Open Closed 07:30 07:30 07:30 07:30 07:30 08:00 
----Close Closed 18:00 18:00 18:00 18:00 18:00 12:00 

--exec [spDIAL_Locations_Schedule] 231
--exec [spDIAL_Locations_Schedule] 104
/*
declare @myOpenHour VARCHAR(300)
exec [spDIAL_Locations_OpenHour] 231, @myOpenHour  output
select @myOpenHour

*/
ALTER Proc [dbo].[spDIAL_Locations_OpenHour]
@Branch_Code int 
,@output VARCHAR(300) output
as
begin
	
		--set nocount on
	--declare @Branch_Code int =104

		select BRANACH, WORK_FROM, WORK_TO, CASE WHEN KIND_DAY_CODE = 1THEN 8 ELSE KIND_DAY_CODE END KIND_DAY_CODE
		INTO #mySchedule
		from BRANACH_SCHEDULES (nolock)  
		where BRANACH = @Branch_Code
		and KIND_DAY_CODE between 1 and 7
		
		
		--update #mySchedule
		--set WORK_FROM =32400, WORK_TO =61200
		--where KIND_DAY_CODE in (7)
		
		
		--update #mySchedule
		--set WORK_FROM =25200, WORK_TO =61200
		--where KIND_DAY_CODE in (8)
		
		--select * from #mySchedule
		
	Declare @iCount int , @iTotalCount int =8 , @sOpenSchedule varchar(300),  @sOpenScheduleDay varchar(300) 
	,@sOpenScheduleMessage varchar(300)
	,@iLastMaxKindofDay int=0, @iLastMinKindofDay int 
	,@sLastMaxKindofDay varchar(100), @sLastMinKindofDay varchar(100)
	,@iCount_out int =1, @iTotalCount_out int =5
	
	while (@iCount_out <=@iTotalCount_out)
	begin

	if @iCount_out =1
		select @iLastMinKindofDay = MIN(KIND_DAY_CODE)  from #mySchedule (nolock) where BRANACH = @Branch_Code and WORK_FROM != WORK_TO   --mean open
	else
		select @iLastMinKindofDay = MIN(KIND_DAY_CODE)  from #mySchedule (nolock) where BRANACH = @Branch_Code and WORK_FROM != WORK_TO  and KIND_DAY_CODE > @iLastMaxKindofDay--mean open
	
	--print 'test5' 
	--print @iLastMinKindofDay
	--print @iLastMaxKindofDay
	
	if @iLastMinKindofDay > @iLastMaxKindofDay
		select @iCount = @iLastMinKindofDay
	else
		break
	
	--select @iCount = @iLastMinKindofDay
	While (@iCount <= @iTotalCount) --7 since there is @iCount +1
	begin
	
		if @iCount =8 --Sunday
		begin
			select @iLastMaxKindofDay =8 --since there is @iCount +1
			break
		end
		if exists(	
				select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount and WORK_FROM != WORK_TO 
				except
				select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount +1  and WORK_FROM != WORK_TO 
				)
		begin
			select @iLastMaxKindofDay = @iCount
			break
		end
	
	
		select @iCount =@iCount +1
	end
	
	print @iLastMinKindofDay
	print @iLastMaxKindofDay
	
	if @iLastMinKindofDay = @iLastMaxKindofDay
	begin
		select @sOpenScheduleDay =''
	
	
		select @sOpenScheduleDay = case when @iLastMinKindofDay= 8 then  'Sun '
					when @iLastMinKindofDay=2 then  'Mon ' 
					when @iLastMinKindofDay=3 then   'Tue '
					when @iLastMinKindofDay=4 then  'Wed '
					when @iLastMinKindofDay=5 then  'Thu '
					when @iLastMinKindofDay=6 then  'Fri '
					when @iLastMinKindofDay=7 then  'Sat '
					end,	
		 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
					+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
		from #mySchedule
		where KIND_DAY_CODE = @iLastMinKindofDay
		
		print @sOpenScheduleDay
		print @sOpenSchedule
	end
	else
	begin
	
		select @sLastMaxKindofDay  = case when @iLastMaxKindofDay= 8 then  'Sun '
					when @iLastMaxKindofDay=2 then  'Mon ' 
					when @iLastMaxKindofDay=3 then   'Tue '
					when @iLastMaxKindofDay=4 then  'Wed '
					when @iLastMaxKindofDay=5 then  'Thu '
					when @iLastMaxKindofDay=6 then  'Fri '
					when @iLastMaxKindofDay=7 then  'Sat '
					end
		,@sLastMinKindofDay = case when @iLastMinKindofDay= 8 then  'Sun '
					when @iLastMinKindofDay=2 then  'Mon ' 
					when @iLastMinKindofDay=3 then   'Tue '
					when @iLastMinKindofDay=4 then  'Wed '
					when @iLastMinKindofDay=5 then  'Thu '
					when @iLastMinKindofDay=6 then  'Fri '
					when @iLastMinKindofDay=7 then  'Sat '
					end	
	
	
		select @sOpenScheduleDay = @sLastMinKindofDay +' - '+ @sLastMaxKindofDay,	
		 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
					+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
		from #mySchedule
		where KIND_DAY_CODE = @iLastMinKindofDay
	
	print @sLastMinKindofDay
	print @sLastMaxKindofDay
	
	print @sOpenScheduleDay
		print @sOpenSchedule
	
	end
	
	if LEN(@sOpenScheduleMessage) >0
		select @sOpenScheduleMessage = @sOpenScheduleMessage +', ' + @sOpenScheduleDay + @sOpenSchedule
	else
		select @sOpenScheduleMessage =  @sOpenScheduleDay + @sOpenSchedule
		
	print @sOpenScheduleMessage
	
	
	select @iCount_out = @iCount_out +1
	end
	
	select @output =@sOpenScheduleMessage

	--select @sOpenScheduleMessage as Open_Hour
	--Next round
	
	--select @iLastMinKindofDay = MIN(KIND_DAY_CODE)  from #mySchedule (nolock) where BRANACH = @Branch_Code and WORK_FROM != WORK_TO  and KIND_DAY_CODE > @iLastMaxKindofDay--mean open
	
	
	--if @iLastMinKindofDay > @iLastMaxKindofDay
	--begin
	--select @iCount = @iLastMinKindofDay

	--While (@iCount <= @iTotalCount) --7 since there is @iCount +1
	--begin
	
	--	if @iCount =8 --Sunday
	--	begin
	--		select @iLastMaxKindofDay =8 --since there is @iCount +1
	--		break
	--	end
	--	if exists(	
	--			select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount and WORK_FROM != WORK_TO 
	--			except
	--			select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount +1  and WORK_FROM != WORK_TO 
	--			)
	--	begin
	--		select @iLastMaxKindofDay = @iCount
	--		break
	--	end
	
	
	--	select @iCount =@iCount +1
	--end
	
	----print 'test'
	----print @iLastMinKindofDay
	----print @iLastMaxKindofDay
	
	--if @iLastMinKindofDay = @iLastMaxKindofDay
	--begin
	--	select @sOpenScheduleDay =''
	
	
	--	select @sOpenScheduleDay = case when @iLastMinKindofDay= 8 then  'Sun '
	--				when @iLastMinKindofDay=2 then  'Mon ' 
	--				when @iLastMinKindofDay=3 then   'Tue '
	--				when @iLastMinKindofDay=4 then  'Wed '
	--				when @iLastMinKindofDay=5 then  'Thu '
	--				when @iLastMinKindofDay=6 then  'Fri '
	--				when @iLastMinKindofDay=7 then  'Sat '
	--				end,	
	--	 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
	--				+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
	--	from #mySchedule
	--	where KIND_DAY_CODE = @iLastMinKindofDay
		
	--	print @sOpenScheduleDay
	--	print @sOpenSchedule
	--end
	--else
	--begin
	
	--	select @sLastMaxKindofDay  = case when @iLastMaxKindofDay= 8 then  'Sun '
	--				when @iLastMaxKindofDay=2 then  'Mon ' 
	--				when @iLastMaxKindofDay=3 then   'Tue '
	--				when @iLastMaxKindofDay=4 then  'Wed '
	--				when @iLastMaxKindofDay=5 then  'Thu '
	--				when @iLastMaxKindofDay=6 then  'Fri '
	--				when @iLastMaxKindofDay=7 then  'Sat '
	--				end
	--	,@sLastMinKindofDay = case when @iLastMinKindofDay= 8 then  'Sun '
	--				when @iLastMinKindofDay=2 then  'Mon ' 
	--				when @iLastMinKindofDay=3 then   'Tue '
	--				when @iLastMinKindofDay=4 then  'Wed '
	--				when @iLastMinKindofDay=5 then  'Thu '
	--				when @iLastMinKindofDay=6 then  'Fri '
	--				when @iLastMinKindofDay=7 then  'Sat '
	--				end	
	
	
	--	select @sOpenScheduleDay = @sLastMinKindofDay +' - '+ @sLastMaxKindofDay,	
	--	 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
	--				+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
	--	from #mySchedule
	--	where KIND_DAY_CODE = @iLastMinKindofDay
	
	----print @sLastMinKindofDay
	----print @sLastMaxKindofDay
	
	----print @sOpenScheduleDay
	----	print @sOpenSchedule
	
	--end
	
	--if LEN(@sOpenScheduleMessage) >0
	--	select @sOpenScheduleMessage = @sOpenScheduleMessage +', ' + @sOpenScheduleDay + @sOpenSchedule
	--else
	--	select @sOpenScheduleMessage =  @sOpenScheduleDay + @sOpenSchedule
		
	--print @sOpenScheduleMessage
	
	--end
	
	
	----Next round
	----select *  from #mySchedule (nolock) where BRANACH = @Branch_Code and WORK_FROM != WORK_TO  and KIND_DAY_CODE > @iLastMaxKindofDay--mean open
	
	--select @iLastMinKindofDay = MIN(KIND_DAY_CODE)  from #mySchedule (nolock) where BRANACH = @Branch_Code and WORK_FROM != WORK_TO  and KIND_DAY_CODE > @iLastMaxKindofDay--mean open
	
	
	--if @iLastMinKindofDay > @iLastMaxKindofDay
	--begin
	--select @iCount = @iLastMinKindofDay
	----select @iLastMinKindofDay =2
	--While (@iCount <= @iTotalCount) --7 since there is @iCount +1
	--begin
	
	--	if @iCount =8 --Sunday
	--	begin
	--		select @iLastMaxKindofDay =8 --since there is @iCount +1
	--		break
	--	end
	--	if exists(	
	--			select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount and WORK_FROM != WORK_TO 
	--			except
	--			select WORK_FROM, WORK_TO  from #mySchedule (nolock) where BRANACH = @Branch_Code and KIND_DAY_CODE =@iCount +1  and WORK_FROM != WORK_TO 
	--			)
	--	begin
	--		select @iLastMaxKindofDay = @iCount
	--		break
	--	end
	
	
	--	select @iCount =@iCount +1
	--end
	
	--print 'test'
	--print @iLastMinKindofDay
	--print @iLastMaxKindofDay
	
	--if @iLastMinKindofDay = @iLastMaxKindofDay
	--begin
	--	select @sOpenScheduleDay =''
	
	
	--	select @sOpenScheduleDay = case when @iLastMinKindofDay= 8 then  'Sun '
	--				when @iLastMinKindofDay=2 then  'Mon ' 
	--				when @iLastMinKindofDay=3 then   'Tue '
	--				when @iLastMinKindofDay=4 then  'Wed '
	--				when @iLastMinKindofDay=5 then  'Thu '
	--				when @iLastMinKindofDay=6 then  'Fri '
	--				when @iLastMinKindofDay=7 then  'Sat '
	--				end,	
	--	 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
	--				+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
	--	from #mySchedule
	--	where KIND_DAY_CODE = @iLastMinKindofDay
		
	--	print @sOpenScheduleDay
	--	print @sOpenSchedule
	--end
	--else
	--begin
	
	--	select @sLastMaxKindofDay  = case when @iLastMaxKindofDay= 8 then  'Sun '
	--				when @iLastMaxKindofDay=2 then  'Mon ' 
	--				when @iLastMaxKindofDay=3 then   'Tue '
	--				when @iLastMaxKindofDay=4 then  'Wed '
	--				when @iLastMaxKindofDay=5 then  'Thu '
	--				when @iLastMaxKindofDay=6 then  'Fri '
	--				when @iLastMaxKindofDay=7 then  'Sat '
	--				end
	--	,@sLastMinKindofDay = case when @iLastMinKindofDay= 8 then  'Sun '
	--				when @iLastMinKindofDay=2 then  'Mon ' 
	--				when @iLastMinKindofDay=3 then   'Tue '
	--				when @iLastMinKindofDay=4 then  'Wed '
	--				when @iLastMinKindofDay=5 then  'Thu '
	--				when @iLastMinKindofDay=6 then  'Fri '
	--				when @iLastMinKindofDay=7 then  'Sat '
	--				end	
	
	
	--	select @sOpenScheduleDay = @sLastMinKindofDay +' - '+ @sLastMaxKindofDay,	
	--	 @sOpenSchedule = left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_FROM),5) + ' - '
	--				+left([dbo].[fn_ShowTimeStamp_fromSecSinceMidnight](WORK_To),5)
	--	from #mySchedule
	--	where KIND_DAY_CODE = @iLastMinKindofDay
	
	--print @sLastMinKindofDay
	--print @sLastMaxKindofDay
	
	--print @sOpenScheduleDay
	--	print @sOpenSchedule
	
	--end
	
	--if LEN(@sOpenScheduleMessage) >0
	--	select @sOpenScheduleMessage = @sOpenScheduleMessage +', ' + @sOpenScheduleDay + @sOpenSchedule
	--else
	--	select @sOpenScheduleMessage =  @sOpenScheduleDay + @sOpenSchedule
		
	--print @sOpenScheduleMessage
	
	--end
	
	drop table #mySchedule

end



