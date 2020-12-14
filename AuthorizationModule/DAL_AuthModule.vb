
Public Class DAL_AuthModule
    Private BaseConn As New SQLConn()
    Private ObjDalGeneral As DAL_General

    Public Function CreateFormApproval(ByVal _strPath As String, ByVal _strPwd As String, ByVal _cid As Integer, ByVal _menuid As String, ByVal _bspid As Integer,
                                       ByVal _vouno As String, ByVal _updatedby As Integer, _updatedate As DateTime, ByRef ErrNo As Integer) As String
        Dim ErrString As String = ""
        ErrNo = 0
        Try
            BaseConn.Open(_strPath, _strPwd)
            BaseConn.cmd = New SqlClient.SqlCommand("CreateFormApproval", BaseConn.cnn)
            BaseConn.cmd.CommandType = CommandType.StoredProcedure
            BaseConn.cmd.Parameters.AddWithValue("@CID", _cid)
            BaseConn.cmd.Parameters.AddWithValue("@MenuID", _menuid)
            BaseConn.cmd.Parameters.AddWithValue("@BusinessPeriodID", _bspid)
            BaseConn.cmd.Parameters.AddWithValue("@VouNo", _vouno)

            BaseConn.cmd.Parameters.AddWithValue("@CreatedBy", _updatedby)
            BaseConn.cmd.Parameters.AddWithValue("@CreatedDate", _updatedate)
            BaseConn.cmd.Parameters.AddWithValue("@ERRORNO", SqlDbType.Int).Direction = ParameterDirection.Output
            BaseConn.cmd.Parameters.Add("@ERRORDESC", SqlDbType.VarChar, 50).Direction = ParameterDirection.Output
            BaseConn.cmd.ExecuteNonQuery()
            ErrNo = BaseConn.cmd.Parameters("@ERRORNO").Value.ToString
            ErrString = BaseConn.cmd.Parameters("@ERRORDESC").Value.ToString
        Catch ex As Exception
            ErrString = ex.Message
            ObjDalGeneral = New DAL_General(_cid)
            ObjDalGeneral.Elog_Insert(_cid, _strPath, _strPwd, _bspid, _updatedby, _updatedate, "", "Auth", ErrNo, "Error in " & _vouno & " ", ex.Message, 5, 3, 1, ErrNo)
            ErrNo = Err.Number
        Finally
            BaseConn.Close()
        End Try

        Return ErrString
    End Function

    Public Function GetFormApproval(ByVal _strPath As String, ByVal _strPwd As String, ByVal _cid As Integer, ByVal _menuid As String, ByVal _vouno As String, ByRef ErrNo As Integer) As DataSet
        GetFormApproval = New DataSet
        Try
            ErrNo = 0
            BaseConn.Open(_strPath, _strPwd)
            BaseConn.cmd = New SqlClient.SqlCommand("[GetFormApproval]", BaseConn.cnn)
            BaseConn.cmd.CommandType = CommandType.StoredProcedure
            BaseConn.cmd.Parameters.AddWithValue("@CID", _cid)
            BaseConn.cmd.Parameters.AddWithValue("@MenuID", _menuid)
            BaseConn.cmd.Parameters.AddWithValue("@VouNo", _vouno)

            BaseConn.da = New SqlClient.SqlDataAdapter(BaseConn.cmd)
            'Dim ds As New DataSet
            BaseConn.da.Fill(GetFormApproval)

        Catch ex As Exception
            ErrNo = 1
            'ErrMsg = ex.Message ' "Problem in Updating Invoice"
        Finally
            BaseConn.Close()
        End Try
        Return GetFormApproval
    End Function

    Public Function CreateFormApprovalSub(ByVal _strPath As String, ByVal _strPwd As String, ByVal _cid As Integer, ByVal _menuid As String, ByVal _vouno As String,
                                          ByVal _approverlevel As Integer, ByVal _updatedby As Integer, ByVal _updatedate As DateTime,
                                          ByVal _approvedstatus As Boolean, ByRef ErrNo As Integer) As String
        Dim ErrString As String = ""
        ErrNo = 0
        Try
            BaseConn.Open(_strPath, _strPwd)
            BaseConn.cmd = New SqlClient.SqlCommand("CreateFormApprovalSub", BaseConn.cnn)
            BaseConn.cmd.CommandType = CommandType.StoredProcedure
            BaseConn.cmd.Parameters.AddWithValue("@CID", _cid)
            BaseConn.cmd.Parameters.AddWithValue("@MenuID", _menuid)
            BaseConn.cmd.Parameters.AddWithValue("@VouNo", _vouno)
            BaseConn.cmd.Parameters.AddWithValue("@Approverlevel", _approverlevel)
            BaseConn.cmd.Parameters.AddWithValue("@CreatedBy", _updatedby)
            BaseConn.cmd.Parameters.AddWithValue("@CreatedDate", _updatedate)
            BaseConn.cmd.Parameters.AddWithValue("@ApprovedStatus", _approvedstatus)

            BaseConn.cmd.Parameters.AddWithValue("@ERRORNO", SqlDbType.Int).Direction = ParameterDirection.Output
            BaseConn.cmd.Parameters.Add("@ERRORDESC", SqlDbType.VarChar, 50).Direction = ParameterDirection.Output
            BaseConn.cmd.ExecuteNonQuery()
            ErrNo = BaseConn.cmd.Parameters("@ERRORNO").Value.ToString
            ErrString = BaseConn.cmd.Parameters("@ERRORDESC").Value.ToString
        Catch ex As Exception
            ErrString = ex.Message
            ObjDalGeneral = New DAL_General(_cid)
            ObjDalGeneral.Elog_Insert(_cid, _strPath, _strPwd, 0, _updatedby, _updatedate, "", "Auth", ErrNo, "Error in " & _vouno & " ", ex.Message, 5, 3, 1, ErrNo)
            ErrNo = Err.Number
        Finally
            BaseConn.Close()
        End Try

        Return ErrString
    End Function

    Public Function UpdateFormApprovalStatus(ByVal _strPath As String, ByVal _strPwd As String, ByVal _cid As Integer, ByVal _menuid As String, ByVal _vouno As String,
                                          ByVal _approverlevel As Integer, ByRef ErrNo As Integer) As String
        Dim ErrString As String = ""
        ErrNo = 0
        Try
            BaseConn.Open(_strPath, _strPwd)
            BaseConn.cmd = New SqlClient.SqlCommand("UpdateFormApprovalStatus", BaseConn.cnn)
            BaseConn.cmd.CommandType = CommandType.StoredProcedure
            BaseConn.cmd.Parameters.AddWithValue("@CID", _cid)
            BaseConn.cmd.Parameters.AddWithValue("@MenuID", _menuid)
            BaseConn.cmd.Parameters.AddWithValue("@VouNo", _vouno)
            BaseConn.cmd.Parameters.AddWithValue("@Approverlevel", _approverlevel)

            BaseConn.cmd.Parameters.AddWithValue("@ERRORNO", SqlDbType.Int).Direction = ParameterDirection.Output
            BaseConn.cmd.Parameters.Add("@ERRORDESC", SqlDbType.VarChar, 50).Direction = ParameterDirection.Output
            BaseConn.cmd.ExecuteNonQuery()
            ErrNo = BaseConn.cmd.Parameters("@ERRORNO").Value.ToString
            ErrString = BaseConn.cmd.Parameters("@ERRORDESC").Value.ToString
        Catch ex As Exception
            ErrString = ex.Message
            'ObjDalGeneral = New DAL_General(_cid)
            'ObjDalGeneral.Elog_Insert(_cid, _strPath, _strPwd, 0, _updatedby, _updatedate, "", "Auth", ErrNo, "Error in " & _vouno & " ", ex.Message, 5, 3, 1, ErrNo)
            ErrNo = Err.Number
        Finally
            BaseConn.Close()
        End Try

        Return ErrString
    End Function
End Class
