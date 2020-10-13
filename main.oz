functor

import
    Application(exit:Exit)
    System
    Browser(browse:Browse)
    OS
define
    {System.showInfo 'Task 1'}
    fun {GenerateOdd Start End}
        if Start > End then 
            nil
        else
            if {Abs Start mod 2} == 1 then
                local
                    NewValue = Start + 2
                in
                    Start|{GenerateOdd NewValue End}
                end
            else
                local
                    NewValue = Start + 1
                in
                    {GenerateOdd NewValue End}
                end
            end
        end
    end

    % Prints: [~3 ~1 1 3 5 7]
    {System.showInfo 'Running {GenerateOdd ~3 10} ...'}
    {Browse thread {GenerateOdd ~3 10} end} % browse stream
    {System.show {GenerateOdd ~3 10}} % print list
    
    % Prints: [3]
    {System.showInfo '\nRunning {GenerateOdd 3 3} ...'}
    {Browse thread {GenerateOdd 3 3} end}
    {System.show {GenerateOdd 3 3} }

    % Prints: nil
    {System.showInfo '\nRunning {GenerateOdd 2 2} ...'}
    {Browse thread {GenerateOdd 2 2} end}
    {System.show {GenerateOdd 2 2}}
    % END OF TASK 1 ----------------------------------------------

    {System.showInfo '\n\nTask 2'}
    fun {Product L} 
        case L of Head|Tail then
            Head * {Product Tail}
        else
            1
        end
    end
    {System.showInfo 'running {Product [1 2 3 4]} ...'}
    % Prints: 24
    {System.show {Product [1 2 3 4]}}
    % END OF TASK 2 ----------------------------------------------


    {System.showInfo '\n\nTask 3'}
    {System.showInfo 'Running example, please read source code comments ...'}
    local 
        Y

        fun {Consume Ls}
            case Ls of H|T then
                H * 2 | {Consume T}
            else
                nil
            end
        end
    in
        thread 
            Y = {Consume thread {GenerateOdd 0 1000} end}
            % If we want to declare a display at this point, we have to use browse
            % for concurrency
            {Browse Y.1}
            {Browse Y.2.1}
            {Browse Y.2.2.1}

            % Since we produce and consume in two different threads, OZ can use the fact that X is a stream
            % to read values from it before the whole dataset is computated. This means that one core on the CPU
            % can perform our multiplication while another core is still generating odd numbers. There is some
            % scheduling happening behind the scenes by Oz to make this safe of course.
            
            % So to summerize. Instead of our program running like this:
            % Produce: ------------              *~1000*
            % Consume:             ------------- *~2000*
            % Time     ------------------------- *~2000*
            
            % Oz can make it run something like this:
            % Produce: --- -- ------  *~1000*
            % Consume:   --- -------- *~1000*
            % Time     -------------- *~1000*
        end

        % Suspend main thread until Y is assigned
        {Wait Y}

        % At this point we can show Y as we have waited 
        {System.show Y.1}
        {System.show Y.2.1}
        {System.show Y.2.2.1}
    end
    % END OF TASK 3 ----------------------------------------------


    {System.showInfo '\n\nTask 4'}
    local 
        X
        Y
        % Copy GenerateOdd with lazy annotation
        fun lazy {GenerateOddLazy Start End}
            if Start > End then 
                nil
            else
                if Start mod 2 == 1 then
                    local
                        NewValue = Start + 2
                    in
                        Start|{GenerateOddLazy NewValue End}
                    end
                else
                    local
                        NewValue = Start + 1
                    in
                        {GenerateOddLazy NewValue End}
                    end
                end
            end
        end
    in
        % Example to showcase how lazy enables us to generate towards infinity
        {System.showInfo '\nRunning X = {GenerateOddLazy 0 9999999999999999}'}
        thread X = {GenerateOddLazy 0 9999999999999999} end
        thread
            {System.showInfo '\nReading X in another thread'}
            {System.showInfo 'X.1:\t\t'#X.1}
            {System.showInfo 'X.2.1:\t\t'#X.2.1}
            {System.showInfo 'X.2.2.1:\t'#X.2.2.1}
            Y = X
        end

        {Wait Y} % Use Y to control execution of prints and stop program from executing the next task
        {System.showInfo '\nLeaving X scope which will exit generate thread'}
    end

    % Here we change our producer to be 'lazy' annotated. This makes the program change its behaviour
    % To only run a new recursive call if needed. In other languages this usually done by using 'generators'
    % Which are a special type of function with a state. They also often use the term 'yield' instead of return when 
    % they complete one computation. Generators are a subset of Coroutines. The main differenece between the two 
    % is the level of control of entry points. Coroutines can have multiple entry points on repeated entry, Generators
    % can not. 
    % Sources:
    % https://en.wikipedia.org/wiki/Generator_(computer_programming)
    % https://en.wikipedia.org/wiki/Coroutine

    % So to summarize: 
    % Instead of our previous execution that looked somewhat like this:
    % Oz can make it run like this:
    % Produce: --- -- ------  *~1000*
    % Consume:   --- -------- *~1000*
    % Time     -------------- *~1000* 
    
    % Our exection looks more like this
    % Produce: ---   *~4*    
    % Consume:   --- *~4*
    % Time     ----- *~4*
    % Caused by us only using 3 'products' 
    % END OF TASK 4 ----------------------------------------------


    {System.showInfo '\n\nTask 5'}

    % Copy paste from task description
    % Creates a random number from Min (Inclusive) to Max (Inclusive)
    fun {RandomInt Min Max}
        X = {OS.rand}
        MinOS
        MaxOS
    in
        {OS.randLimits ?MinOS ?MaxOS} Min + X * (Max - Min) div (MaxOS - MinOS)
    end
    % Task 5 a
    {System.showInfo '\na) Making 4 hammers. Please wait ...'}

    % Creates a hammer after ~1 second (In practice, a bit longer than 1 second)
    fun lazy {HammerFactory} 
        Quality = {RandomInt 1 10}
    in
        {Time.delay 1000} 
        if Quality == 1 then
            defect|{HammerFactory}
        else 
            working|{HammerFactory}
        end
    end

    % Test {HammerFactory}
    local 
        HammerTime 
    in
        HammerTime = {HammerFactory}
        _ = HammerTime.2.2.2.1 % force production of 4 hammers
        {System.show HammerTime}
    end

    {System.showInfo '\nb) Counting working hammers between 0 and 10. Please wait ...'}
    % Task 5 b
    fun {HammerConsumer HammerStream N}
        N2 = N - 1
    in
        if N2 < 0 then
            0
        else 
            case HammerStream.1 of defect then
                {HammerConsumer HammerStream.2 N2}
            [] working then
                1 + {HammerConsumer HammerStream.2 N2}
            else
                0
            end
        end
    end

    local HammerTime Consumer in
        HammerTime = {HammerFactory}
        Consumer = {HammerConsumer HammerTime 10}
        {System.show Consumer}
    end

    % Task 5 c
    {System.showInfo '\nc) Bounding buffer. Please wait ...'}

    fun {BoundedBuffer HammerStream N}
        % Procedure that visits an element to bind it
        proc {Bind S N} 
            if N < 1 then
                skip
            else
                {Bind S.2 N - 1}
            end
        end

        Buffer
    in  
        % Create a bounded buffer in another thread
        thread
            Buffer = HammerStream
            {Bind Buffer N}
        end
        % Return buffer
        Buffer
    end
    
    {System.showInfo '\nStarting no bound buffer test'}
    local HammerStream StartTime Consumer in
        {System.showInfo '\nProgram taking a 6 second coffee break :). Please wait ...'}
        StartTime = {Time.time}

        % Create stream
        HammerStream = {HammerFactory}

        % Suspend thread, we have no other threading going on so the process will sleep
        % zzz
        {Delay 6000}

        % Here we find out we need 10 hammers, we have to create them all 
        % at this point. Would be greate if we utilized the 6 seconds of suspension ...
        {System.showInfo '\nConsuming 10 from buffer. Please wait ...'}
        Consumer = {HammerConsumer HammerStream 10}

        {System.showInfo "Used "#{Time.time} - StartTime#" seconds on test"}
        {System.show Consumer}
    end

    {System.showInfo '\nStarting bound buffer test'}
    local HammerStream Buffer StartTime Consumer in
        {System.showInfo '\nPrecomputing 6 in buffer. Please wait ...'}
        % Record time when we start test
        StartTime = {Time.time} 

        % Here we create stream and then a bounded buffer while we wait
        % for delay. Even though the thread is halting (or doing something else),
        % we have another thread that is bindnig the buffer over time as long as 
        % the scheduler is good to us ... 
        HammerStream = {HammerFactory}
        Buffer = {BoundedBuffer HammerStream 6}
        {Delay 6000}

        % At this point we have haltet current thread in 6 seconds, hopefully
        % the buffer has grown in the meantime. Then when we request the stream
        % there should be 6 ready to go, meaning we have to wait for 4.
        {System.showInfo '\nConsuming 10 from buffer. Please wait ...'}
        Consumer = {HammerConsumer Buffer 10}

        % Use current time - start time to figure out run time in seconds
        % The sum should be about 10 as we use the 6 start seconds to bind the buffer
        {System.showInfo "Used "#{Time.time} - StartTime#" seconds on test"}
        {System.show Consumer}
    end
    {Exit 0}
end
