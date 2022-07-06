'NR Video Agent Example - Main'

sub RunUserInterface(args)
    if args.RunTests = "true" and type(TestRunner) = "Function" then
        print "Run tests"
        Runner = TestRunner()

        Runner.SetFunctions([
            TestSuite__Main
            TestSuite__Logs
            TestSuite__Metrics
        ])

        Runner.Logger.SetVerbosity(3)
        Runner.Logger.SetEcho(false)
        Runner.Logger.SetJUnit(false)
        Runner.SetFailFast(true)
        
        Runner.Run()
    else
        Main(args)
    end if
end sub

sub Main(aa as Object)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    scene = screen.CreateScene("VideoScene")
    screen.show()
    
    'Init New Relic Agent (FILL YOUR CREDENTIALS, ACCOUNT_ID and API_KEY)
    m.nr = NewRelic("ACCOUNT_ID", "API_KEY", "US", true)
    nrAppStarted(m.nr, aa)
    'Send a custom system
    nrSendSystemEvent(m.nr, "TEST_ACTION")
    'generate a custom pattern for HTTP_ system event grouping
    patgen = createObject("roSGNode", "PatternGen")
    nrSetGroupingPatternGenerator(m.nr, patgen)
    
    'Pass NewRelicAgent object to scene
    scene.setField("nr", m.nr)
    'Observe scene field "moteButton" to capture "back" button and abort the execution
    scene.observeField("moteButton", m.port)
    
    'Activate system tracking
    m.syslog = NewRelicSystemStart(m.port)
    
    runSearchTask("hello")
    
    while(true)
        msg = wait(0, m.port)
        
        if nrProcessMessage(m.nr, msg) = false
            'Is not a system message captured by New Relic Agent
            print "Msg = ", msg
            
            if type(msg) = "roSGNodeEvent"
                if msg.getField() = "moteButton"
                    print "moteButton, data = ", msg.getData()
                    if msg.getData() = "back" 
                        exit while
                    end if
                    if msg.getData() = "OK"
                        'force crash
                        print "Crash!"
                        x = invalid
                        x.anyFoo()
                    end if
                end if
            end if
        end if
    end while
end sub

'Test task to show how to generate http events
function runSearchTask(search as String)
    task = createObject("roSGNode", "SearchTask")
    task.setField("nr", m.nr)
    task.setField("searchString", search)
    task.control = "RUN"
end function
