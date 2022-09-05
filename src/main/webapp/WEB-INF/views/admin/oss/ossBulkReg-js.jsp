<%@ page contentType="text/html; charset=utf-8" pageEncoding="utf-8"%>
<%@ include file="/WEB-INF/constants.jsp"%>

<script>
    var ossData = [];
    var grid = "#list";
    var licenseNames = [];

    function showErrorMsg() {

        alertify.error('<spring:message code="msg.common.valid"/>', 0);

        $('.ajax-file-upload-statusbar').fadeOut('slow');
        $('.ajax-file-upload-statusbar').remove();
    }

    $(document).ready(function()
    {

        $("#btn").click(() => {
            $.ajax({
                type: "POST",
                contentType: 'application/json',
                url: "/oss/bulkRegAjax",
                data: JSON.stringify(OssBulkGridUtils.bulkSaveRequestData()),
                dataType: "json",
                success: (data) => {
                    if (data['res'] == true && data['value'] != []) {
                        fn.checkLoaded(data['value']);
                        alertify.alert('<spring:message code="msg.common.success" />', function(){});
                    } else if (data['res'] == false) {
                            showErrorMsg();
                    }
                },
                error: (e) => {
                    console.log(e);
                }
            })
        })


        $("#list").jqGrid({
            datatype: "local",
            data : ossData,
            colNames:['id', 'OSS Name','Nickname','Version','Declared License','Detected License','Copyright',
                'Homepage','Download URL',  'Summary Description', 'Attribution','Comment', 'Status'],
            colModel: [
                { name: 'gridId', 	index: 'gridId', width: 75, key:true, hidden: true},
                { name: 'ossName', index: 'ossName', width: 200, align: 'left', editable:true},
                { name: 'ossNicknames', index: 'ossNickNames', width: 200, align: 'left', editable:true},
                { name: 'ossVersion', index: 'ossVersion', width: 75, align: 'left', editable:true},
                { name: 'declaredLicenses', index: 'declaredLicenses', width: 300, align: 'left', editable:true},
                { name: 'detectedLicenses', index: 'detectedLicenses', width: 300, align: 'left', editable:true},
                { name: 'copyright', index: 'copyright', width: 200, align: 'left', editable:true},
                { name: 'homepage', index:'homepage', width: 250, align: 'left', editable:true},
                { name: 'downloadLocation', index:'downloadLocation', width: 150, align: 'left', editable:true},
                { name: 'summaryDescription', index:'summaryDescription', width: 150, align: 'left', editable:true},
                { name: 'attribution', index:'attribution', width: 150, align: 'left', editable:true},
                { name: 'comment', index:'comment', width: 150, align: 'left', editable:true},
                { name: 'status', index:'status', width: 150, align: 'left'}
            ],
            viewrecords: true,
            rowNum: ${ct:getConstDef("DISP_PAGENATION_DEFAULT")},
            rowList: [${ct:getConstDef("DISP_PAGENATION_LIST_STR")}],
            autowidth: true,
            gridview: true,
            height: 'auto',
            pager: '#pager',
            multiselect: true,

            /** 더블클릭 하면 편집 */
            ondblClickRow: function(rowid,iRow,iCol,e) {
                OssBulkGridUtils.editRow(rowid);
            },

            /** 클릭하면 체크박스 선택/선택해제 */
            onSelectRow: function(id){
                OssBulkGridUtils.selectOrUnselect(id);
            },

            /** 전체선택 체크박스 클릭하면 해당 페이지의 데이터 전체선택 or 전체 선택 해제 */
            onSelectAll: function(aRowids, status) {
                (status) ? OssBulkGridUtils.selectAllPage() : OssBulkGridUtils.unselectAllPage();
            },

            /** 페이지 이동시 선택했었던 데이터 checkbox 표시해주기 */
            loadComplete: function() {
                OssBulkGridUtils.selectMarkWhenPageChange();
            },

            /** 페이지 이동시 마지막으로 편집했던 데이터 저장 */
            onPaging: function() {
                OssBulkGridUtils.saveLastEditedRow();
            }
        });

        var accept1 = '';

        //checking for allowed extensions (xlsx, xls, xlsm)
        <c:forEach var="file" items="${ct:getCodes(ct:getConstDef('CD_FILE_ACCEPT'))}" varStatus="fileStatus">
        <c:if test="${file eq '11'}">
        accept1 = '${ct:getCodeExpString(ct:getConstDef("CD_FILE_ACCEPT"), file)}';
        </c:if>
        </c:forEach>

        $("#csvFile").uploadFile({
            url:'/oss/csvFile',
            multiple:false,
            dragDrop:true,
            fileName:'myfile',
            allowedTypes: accept1,
            sequential:true,
            sequentialCount:1,
            dynamicFormData: function(){
                var data ={ "registFileId" :$('#csvFileId').val(), "tabNm" : "BULK"};
                return data;
            },
            onSuccess:function(files,data,xhr,pd) {
                if (data['res'] == true){
                    fn.addRowsFromExcelImport(data['value']);
                }
                else if(data['res'] == false){
                    showErrorMsg();
                } else {
                    if (data['limitCheck'] == null) {
                        showErrorMsg();
                    }
                }
            }
        });
    });
    var fn = {
        downloadBulkSample : function(type){
            var logiPath = "/sample/FOSSLight-OSS-Bulk-Sample.xls";
            var fileName = "FOSSLight-OSS-Bulk-Sample.xls";

            location.href = '<c:url value="/partner/sampleDownload?fileName='+fileName+'&logiPath='+logiPath+'"/>';
        },

        /**
         * import excel requested datas
         */
        addRowsFromExcelImport: (datas) => {
            OssBulkGridUtils.addNewRows(datas.map(data => data.oss));
        },

        /**
         * Update grid after bulk save
         */
        checkLoaded: (datas) => {
            datas.forEach(data => {
                // update status message
                OssBulkGridUtils.updateCell(data.gridId, "status", data.status)
            });
        },

        /**
         * convert commaed string to array
         * "1,2,3" -> ["1", "2", "3"]
         */
        stringToArray: (string) => {
            if(Array.isArray(string))
                return string;
            if (!string || /^\s*$/.test(string))
                return [];
            return string.split(",").filter(str => (str != ""));
        },
    }

    const OssBulkGridUtils = (function(gridDocumentId) {
        const grid = $(gridDocumentId);
        const selectedIds = new Set(); /** 선택된 데이터id를 따로 관리 */
        let lastSelected = null;

        return {
            getGrid: function() {
                return $(grid);
            },

            reloadGrid: function() {
                grid.trigger('reloadGrid');
            },

            selectOrUnselect: function(gridId) {
                if(selectedIds.has(gridId))
                    selectedIds.delete(gridId);
                else
                    selectedIds.add(gridId);
            },

            selectAllPage: function() {
                this.getCurPageIds().forEach(id => selectedIds.add(id));
            },

            unselectAllPage: function() {
                this.getCurPageIds().forEach(id => selectedIds.delete(id));
            },

            getCurPageIds: function() {
                return grid.jqGrid("getDataIDs");
            },

            getRow: function(gridId) {
                return grid.jqGrid("getLocalRow", gridId);
            },

            getAllRows: function() {
                return grid.jqGrid("getGridParam", "data");
            },

            getSelectedRows: function() {
                const selectedRows = []
                for (let id of selectedIds)
                    selectedRows.push(this.getRow(id));
                return selectedRows;
            },

            selectMarkWhenPageChange: function() {
                for(let id of grid.jqGrid("getDataIDs")) {
                    if(selectedIds.has(id)) {
                        selectedIds.delete(id);
                        grid.jqGrid("setSelection", id);
                    }
                }
            },

            updateCell: function(gridId, column, value){
                grid.jqGrid("setCell", gridId, column, value);
            },

            newGridID: function(){
                return $.jgrid.randId();
            },

            addNewRow: function(newRow) {
                if(!newRow.gridId)
                    newRow.gridId = this.newGridID();
                grid.jqGrid('addRowData', newRow.gridId, newRow);
            },

            addNewRows: function(newRows) {
                newRows.forEach(row => this.addNewRow(row));
                this.reloadGrid();
            },

            editRow: function(gridId) {
                this.saveLastEditedRow();

                lastSelected = gridId;
                grid.jqGrid('editRow', gridId);
            },

            saveRow: function(gridId) {
                grid.jqGrid('saveRow', gridId, {url: 'clientArray'});
            },

            saveLastEditedRow: function() {
                if(lastSelected)
                    this.saveRow(lastSelected);
            },

            bulkSaveRequestData: function() {
                this.saveLastEditedRow();

                return this.getSelectedRows().map(row => {
                    const res = {...row};

                    delete res.status;

                    for (let key in res) {
                        if(res[key] === null || res[key] === undefined)
                            res[key] = "";
                    }

                    // list attributes
                    res.declaredLicenses = fn.stringToArray(res.declaredLicenses);
                    res.detectedLicenses = fn.stringToArray(res.detectedLicenses);
                    res.ossNicknames = fn.stringToArray(res.ossNicknames);
                    return res;
                });
            }
        }
    })(grid);
</script>
