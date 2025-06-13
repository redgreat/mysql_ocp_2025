import React from 'react'
import { useState } from 'react'
import MySQLPracticeExam from './components/MySQLPracticeExam'
import AuthLogin from './components/AuthLogin'

/**
 * 主应用组件，处理认证状态和页面路由
 */
function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  const handleLogin = () => {
    setIsAuthenticated(true)
  }

  return (
    <div>
      {isAuthenticated ? (
        <MySQLPracticeExam />
      ) : (
        <AuthLogin onLogin={handleLogin} />
      )}
    </div>
  )
}

export default App