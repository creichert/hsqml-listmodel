\begin{document}
\usepackage{listings}
\usepackage{underscore}
\usepackage{upquote}

\title{Haskell QML -- List Models in HsQML}
\author{Christopher Reichert}

\maketitle

\begin{abstract}

\href{http://www.gekkou.co.uk/software/hsqml/}{HsQML} is a Haskell binding for
Qt Quick 2 which provides a set of features for integrating QML and Haskell.
You can find complete samples on
\href{http://hackage.haskell.org/package/hsqml-demo-samples}{hackage} which are
great for getting started.

In this post I will discuss how to create a model for a QML
\href{http://qt-project.org/doc/qt-5/qml-qtquick-listview.html}{ListView} in
Haskell using HsQML. I want to thank the author of HsQML for his continued help
and correspondence on this post, the HsQML library, and it's development.

In QML, it is possible to define a
\href{http://qt-project.org/doc/qt-5/qqmlcontext.html#contextObject}{Context
Object} to expose properties from C++. HsQML builds on this by utilizing
objects as the primary bridge of communication between Haskell and QML code.
QML documents may reference an object's properties to fetch data and can also
call an object's methods to invoke actions. This makes for a very clean
decoupling of UI elements and the supporting backend.

The problem is that many types of data we wish to model can get complicated.
QML has different types of views which support arbitrarily complex model
interfaces to represent dynamic datasets. Because there is no facility in HsQML
to define a
\href{http://qt-project.org/doc/qt-5/QAbstractItemModel.html}{QAbstractItemModel}
directly, we can get by with marshalling lists of items in many situations.

\end{abstract}

\section{Why Should I Care?}

Haskell is a very powerful production-ready programming language with an
aptitude for producing software that
\href{http://www.haskell.org/haskellwiki/Why_Haskell_just_works}{just works}.
My work at KDAB with Qt and enthusiasm for Haskell has driven me to research
the various
\href{http://www.haskell.org/haskellwiki/Applications_and_libraries/GUI_libraries}{Haskell
user interface toolkits} and what they may have to offer for developers and
end-users. The HsQML language bindings open up a myriad of opportunity for
Haskell development that is otherwise lacking, under-developed, or often
unwieldy in other toolkits I have worked with.  HsQML brings the power of
native fluid user interfaces to the Haskell programming language which could
open up a wide range of possibilities across mobile, embedded, and desktop
application development.

I won't preach the benefits of adopting Haskell. Rather, if you are using
Haskell (or considering adoption) and curious whether HsQML is a good fit as a
user interface toolkit you might consider:

\begin{itemize}

\item HsQML is cross-platform. Not only does HsQML run on OSX, Windows, and
Linux, it is also possible to port applications to arm chipsets like the
\href{http://www.raspberrypi.org/}{Raspberry Pi}. Although it still needs some
battle testing, this could prove to be a huge step over porting other native
Haskell user interface frameworks or bindings.

\item  HsQML is constantly enhanced with additions to
\href{http://qt-project.org/doc/qt-5/qtquick-index.html}{Qt Quick},
\href{http://qt-project.org/doc/qt-5/qtquickcontrols-index.html}{Qt Quick
Controls} and other ongoing QML enhancements that are not specific to Haskell.
HsQML will continually reap the benefits of work done on the QML engine, QML
proper, and Qt Quick. This is important in a smaller community where developer
resources may be scarce for developing and maintaining new user interface
toolkits.

\item HsQML is a much smaller binding than other toolkits. This could save time
when compiling and also prevent associated issues with Cabal dependencies and
small bugs that tend to crop up from larger bindings from time to time.

\item QML is a simple declarative UI language which gives designers ability to
work alongside backend developers. Nuno Pinheiro, a KDAB designer, highlights
the advantages of using QML from a designers perspective in the slides for
his talk:
\url{http://www.desktopsummit.org/program/sessions/qml-designers-perspective}.

\item HsQML code can generally be written in a highly decoupled manner in
contrast to some of the traditional heavyweight ui toolkits in Haskell like
\href{http://projects.haskell.org/gtk2hs/}{Gtk2Hs} or
\href{http://www.haskell.org/haskellwiki/Applications_and_libraries/GUI_libraries#HTk}{HTK}.
This could potentially lower the barrier of entry for writing user interfaces
in Haskell while developing applications. This is not to suggest decoupling
your ui code from your business logic is impossible, or even difficult in other
toolkits; only that it is a very natural style that HsQML lends itself to.

\item Integration with Javascript is convenient due to HsQML's marshaling
features. The \href{http://hackage.haskell.org/package/hsqml-demo-morris}{HsQML
Morris Demo} is a great example of using a thin JavaScript wrapper to help
manage marshaled data. The goal, however, is to cut down on the amount of
JavaScript code in general.

\item HsQML has thorough test coverage via
\href{http://hackage.haskell.org/package/QuickCheck}{QuickCheck}. QuickCheck is
an amazing combinator library designed to automate testing Haskell code.
QuickCheck is a type-based “property” testing framework.

\begin{quote}
Property-based testing encourages a high level approach to testing in the form
of abstract invariants functions should satisfy universally, with the actual
test data generated for the programmer by the testing library. In this way code
can be hammered with thousands of tests that would be infeasible to write by
hand, often uncovering subtle corner cases that wouldn't be found otherwise.
    -- Real World Haskell - Chapter 11
\end{quote}

\item One major lacking feature for HsQML would be current OpenGL support. I
have had many discussions with the author of HsQML and my impression is that he
plans to implement OpenGL support in the future. Qt3d should should just work
provided that you can add a Qt3d view-port to a Qt Quick scene. The QML
examples in the Qt3d repository don't do this, but I presume it's on their
road-map.

\end{itemize}

\section{Imports}

Our example program requires a few language extensions and imports to get
started.

\begin{code}

{-# LANGUAGE DeriveDataTypeable, TypeFamilies, OverloadedStrings #-}

import Control.Concurrent
import Data.Proxy
import qualified Data.Text as T
import Data.Typeable
import Graphics.QML

\end{code}

While a full explanation of the langauge extensions is beyond the scope of this
post, it`s worth pointing out the extension {\bfseries DeriveDataTypeable} and
{\bfseries Data.Typeable} allow a limited set of type casting utilities.  The
extension DeriveDataTypeable automatically handles data types deriving
Typeable. TypeFamilies are the data type analogue of
\href{http://en.wikipedia.org/wiki/Type_class}{type classes}.
 
\section{Defining QML Types}

Next, A data type representing the QML context object and list item is defined:

\begin{code}

data ContextObj = ContextObj
                { _list :: MVar [ObjRef ListItem]
                } deriving Typeable

data ListItem = ListItem
              { _text :: T.Text
              } deriving Typeable

\end{code}

{\bfseries ContextObj} is a record containing a single field which represents
the list to be modeled in QML. {\bfseries \_list} is of the type {\bfseries
MVar [ObjRef ListItem]}; an MVar to a list of ObjRef ListItems. A breakdown of
the type signature sheds some light on why all the types are necessary:

\begin{itemize}

\item {\bfseries ListItem} is a Haskell record containing the data for each
item.

\item {\bfseries ObjRef ListItem} is a handle to a QML object which wraps
ListItem and makes data accessible to QML. Data types can reap the benefits of
automated marshaling between QML and Haskell when qualified by the type
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#t:ObjRef}{ObjRef},
e.g. `ObjRef tt`.

\item {\bfseries [ObjRef ListItem]} is a list of ObjRef ListItem.

\item {\bfseries MVar [ObjRef ListItem]} is a mutex-protected mutable reference
to the list so that it can be update over the course of the programs execution.
\href{http://hackage.haskell.org/package/base-4.7.0.0/docs/Control-Concurrent-MVar.html}{MVar}
provides an interface to modify and read persistent state concurrently.

\end{itemize}

Although {\bfseries ListItem} only contains text, I find it a bit more useful
as an example if you are working towards implementing more complicated list
model types.

\section{Signals}

Signals are defined as empty data types which implement the
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#t:SignalKeyClass}{SignalKeyClass}
type class and derive
\href{http://hackage.haskell.org/package/base-4.7.0.0/docs/Data-Typeable.html}{Typeable}.
Signals do not have any constructors and thus never exist as values.  The empty
type signatures are used to identify signals at the type-level. In this way,
Signals can be declared  top-level and used in our DefaultClass instances.

\begin{code}
-- Signals
data ListChanged deriving Typeable

instance SignalKeyClass ListChanged where
    type SignalParams ListChanged = IO ()

\end{code}

The signal {\bfseries ListChanged} is fired when a ListItem is added or removed
from the \_list property in ContextObj.

ListChanged does not define any
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#t:SignalParams}{SignalParams}.
The {\bfseries IO ()} (pronounced IO unit or IO action) describes the signal as
an action within the \href{http://www.haskell.org/haskellwiki/IO_inside}{IO
Monad}. The SignalParams type parameter specifies the type signature of the
signal.

\section{Necessary Type Classes}

In order to create QML objects for values of ContextObj and ListItem, we have
to provide class definitions for these object types. This can be done using the
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#t:Defa}{DefaultClass}
typeclass.

\begin{code}

instance DefaultClass ContextObj where
    classMembers = [
          defPropertySigRO "list" (Proxy :: Proxy ListChanged) $ readMVar . _list . fromObjRef
        , defMethod "appendList" appendList
        ]

instance DefaultClass ListItem where
    classMembers = [
          defPropertyRO "text" $ return . _text . fromObjRef
        ]

\end{code}

A DefaultClass can define properties and methods which can be accessed in QML
code.
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#g:6}{defPropertySigRO}
defines a named read-only property with an attached NOTIFY signal. This would
be semantically identical to the Qt C++ macro:

\begin{lstlisting}
     Q_PROPERTY(QList list READ list NOTIFY listChanged)
\end{lstlisting}

{\bfseries defPropertyRO} is no different except that it has no attached NOTIFY
signal. {\bfseries defMethod} defines a named method for running a function in
the IO Monad from QML. This would be semantically similar to using the
Q\_INVOKABLE macro in Qt C++.

{\bfseries ListItem} defines a property {\bfseries text} which returns the
\_text field of a ListItem. ListItem access from QML looks something like this:

\begin{lstlisting}
    ListView {
        model: list
        delegate: Text { text: modelData.text }
    }

\end{lstlisting}

We assign the {\bfseries list} property defined in ContextObj to {\bfseries
model}.  Because {\bfseries list} is not actually a QAbstractItemModel,  there
is no way to implement named roles for our list of items.  {\bfseries
modelData} provides a reference to the corresponding ListItem in the delegate
and is provided by the QML engine for models that only have one role.

\section{Defining QML Functions}

The function {\bfseries appendList} is called by ContextObj and adds a new
element to the mutable list of ListItem's using
\href{http://hackage.haskell.org/package/base-4.7.0.0/docs/Control-Concurrent-MVar.html#v:modifyMVar_}{modifyMVar\_}.

\begin{code}

appendList :: ObjRef ContextObj -> T.Text -> IO ()
appendList co txt = modifyMVar_ list (\ls -> do l <- newObjectDC $ ListItem txt
                                                return (l:ls)) >>
                    fireSignal (Proxy :: Proxy ListChanged) co
    -- Retrieve the list field from the ContextObj
    where list = _list . fromObjRef $ co

\end{code}

\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Objects.html#v:fireSignal}{fireSignal}
is called to notify the list view that changes have been made. {\bfseries
fireSignal} is thread-safe and passes the signal to the event loop thread for
processing. Haskell functions called from QML will be run in the GUI thread.
Use
\href{http://www.haskell.org/ghc/docs/latest/html/libraries/base/Control-Concurrent.html#v:forkIO}{forkIO}
to deal with any long running operations to reduce UI latency.

\section {Marshaling}

HsQML defines
\href{http://hackage.haskell.org/package/hsqml-0.3.0.0/docs/Graphics-QML-Marshal.html#t:Marshal}{Marshal}
instances for several types including Int, Double, Text, Bool, ObjRef t, List
([a]), and Maybe a. As I mentioned earier, defining our types in terms of
{\bfseries ObjRef} allows for automatic marshalling capabilities between the
QML and Haskell code. It is possible to define a Marshal instance for our
ListItem type:

\begin{code}
instance Marshal ListItem where
    type MarshalMode ListItem c d = ModeObjFrom ListItem c
    marshaller = fromMarshaller fromObjRef

\end{code}

However, an instance of `Marshal ListItem` is not needed since we use `ObjRef
ListItem` to reference each list item in our {\bfseries ContextObj} data type.

\section{Putting it all together}

Finally, the main function.

\begin{code}

main :: IO ()
main = do

    l <- newMVar []
    tc <- newObjectDC $ ContextObj l

    runEngineLoop defaultEngineConfig {
      initialDocument = fileDocument "ui.qml"
    , contextObject   = Just $ anyObjRef tc
    }

\end{code}

A newMVar with an empty list is used to construct an instance of ContextObj
using {\bfseries newObjectDC}. The {\bfseries DC} at the end is used on types
that are instances of DefaultClass. {\bfseries runEngineLoop} starts the qml
engine and sets the initial QML document as well as the {\bfseries
contextObject}.

When running the program you may notice the following error:

\begin{quote}
Expression depends on non-NOTIFYable properties
\end{quote}

This can be avoided by using a method with no arguments instead of a property
since there is no need to listen for updates. This would be similar to the
{\bfseries CONST} attribute in the C++ {\bfseries Q\_PROPERTY} macro. There are
plans to support {\bfseries CONST} properties in HsQML in the future.

The complete code for this post can be found at
\url{git@github.com:creichert/hsqml-listmodel.git}. The post is written in
Literate Haskell style and can be compiled directly. Check the README for
instructions on how to build the project.

For a less trivial example of HsQML, you can check out my in-progress port of
the Qt Quick
\href{http://qt-project.org/doc/qt-5/qtquick-demos-stocqt-example.html}{StocQt}
here: \url{https://github.com/creichert/hsqmlstockqt}.

If you have any other questions or would like to know how you can advocate for
Haskell usage feel free to comment!

\end{document}
