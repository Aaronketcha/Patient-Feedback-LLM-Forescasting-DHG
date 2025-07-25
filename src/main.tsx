import './index.css'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Routes, Route } from "react-router-dom"
import Home from './pages/Home'
import Login from './pages/Login'
import SignIn from './pages/SignIn'
import Header from './components/Header'
import Profile from './pages/ProfilePage'
import History from './pages/HistoryPage'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Router>
      <Header />
      <Routes>
        <Route path="/" element={ <Home /> }></Route>
        <Route path="/login" element={ <Login /> }></Route>
        <Route path="/register" element={ <SignIn /> }></Route>
        <Route path="/profile" element={ <Profile /> }></Route>
        <Route path="/history" element={ <History /> }></Route>
      </Routes>
    </Router>
  </StrictMode>,
)
